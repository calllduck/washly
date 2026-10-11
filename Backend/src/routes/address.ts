import { Router, Request, Response } from 'express';
import { prisma } from '../config/prisma.js';
import { authGuard } from '../middleware/authGuard.js';
import { roleGuard } from '../middleware/roleGuard.js';

const router = Router();

// Address management is customer-scoped.
router.use(authGuard, roleGuard('CUSTOMER'));

function isNonEmptyString(v: unknown): v is string {
  return typeof v === 'string' && v.trim().length > 0;
}

// ---------------------------------------------------------------------------
// GET /api/addresses — List all addresses for the authenticated customer
// ---------------------------------------------------------------------------
router.get('/', async (req: Request, res: Response) => {
  try {
    const customerId = req.user!.id;
    const addresses = await prisma.address.findMany({
      where: { userId: customerId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
    return res.json(addresses);
  } catch (error: unknown) {
    console.error('Error fetching addresses:', error);
    return res.status(500).json({ error: 'Failed to fetch addresses.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/addresses — Create a new address
// ---------------------------------------------------------------------------
router.post('/', async (req: Request, res: Response) => {
  try {
    const customerId = req.user!.id;
    const {
      label,
      receiverName,
      phone,
      fullAddress,
      notes,
      latitude,
      longitude,
      isDefault,
    } = req.body ?? {};

    if (!isNonEmptyString(label)) {
      return res.status(400).json({ error: 'Label (e.g. Rumah, Kantor) is required.' });
    }
    if (!isNonEmptyString(fullAddress)) {
      return res.status(400).json({ error: 'Alamat lengkap is required.' });
    }

    const count = await prisma.address.count({ where: { userId: customerId } });
    const shouldBeDefault = count === 0 || Boolean(isDefault);

    // Mock coordinates fallback if not provided: Jakarta South center
    const lat =
      latitude != null && !isNaN(parseFloat(String(latitude)))
        ? parseFloat(String(latitude))
        : -6.2447;
    const lng =
      longitude != null && !isNaN(parseFloat(String(longitude)))
        ? parseFloat(String(longitude))
        : 106.7995;

    const result = await prisma.$transaction(async (tx) => {
      if (shouldBeDefault) {
        await tx.address.updateMany({
          where: { userId: customerId, isDefault: true },
          data: { isDefault: false },
        });
      }

      return tx.address.create({
        data: {
          userId: customerId,
          label: label.trim(),
          receiverName: isNonEmptyString(receiverName) ? receiverName.trim() : null,
          phone: isNonEmptyString(phone) ? phone.trim() : null,
          fullAddress: fullAddress.trim(),
          notes: isNonEmptyString(notes) ? notes.trim() : null,
          latitude: lat,
          longitude: lng,
          isDefault: shouldBeDefault,
        },
      });
    });

    return res.status(201).json(result);
  } catch (error: unknown) {
    console.error('Error creating address:', error);
    return res.status(500).json({ error: 'Failed to create address.' });
  }
});

// ---------------------------------------------------------------------------
// PUT /api/addresses/:id — Update an address
// ---------------------------------------------------------------------------
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const customerId = req.user!.id;
    const addressId = parseInt(String(req.params.id), 10);
    if (isNaN(addressId)) {
      return res.status(400).json({ error: 'Invalid address ID.' });
    }

    const existing = await prisma.address.findUnique({
      where: { id: addressId },
    });

    if (!existing || existing.userId !== customerId) {
      return res.status(404).json({ error: 'Address not found.' });
    }

    const {
      label,
      receiverName,
      phone,
      fullAddress,
      notes,
      latitude,
      longitude,
      isDefault,
    } = req.body ?? {};

    if (label !== undefined && !isNonEmptyString(label)) {
      return res.status(400).json({ error: 'Label cannot be empty.' });
    }
    if (fullAddress !== undefined && !isNonEmptyString(fullAddress)) {
      return res.status(400).json({ error: 'Alamat lengkap cannot be empty.' });
    }

    const markDefault = isDefault !== undefined ? Boolean(isDefault) : false;

    const result = await prisma.$transaction(async (tx) => {
      if (markDefault && !existing.isDefault) {
        await tx.address.updateMany({
          where: { userId: customerId, isDefault: true },
          data: { isDefault: false },
        });
      }

      return tx.address.update({
        where: { id: addressId },
        data: {
          ...(label !== undefined ? { label: label.trim() } : {}),
          ...(receiverName !== undefined ? { receiverName: receiverName ? String(receiverName).trim() : null } : {}),
          ...(phone !== undefined ? { phone: phone ? String(phone).trim() : null } : {}),
          ...(fullAddress !== undefined ? { fullAddress: fullAddress.trim() } : {}),
          ...(notes !== undefined ? { notes: notes ? String(notes).trim() : null } : {}),
          ...(latitude !== undefined ? { latitude: parseFloat(String(latitude)) } : {}),
          ...(longitude !== undefined ? { longitude: parseFloat(String(longitude)) } : {}),
          ...(isDefault !== undefined ? { isDefault: Boolean(isDefault) } : {}),
        },
      });
    });

    return res.json(result);
  } catch (error: unknown) {
    console.error('Error updating address:', error);
    return res.status(500).json({ error: 'Failed to update address.' });
  }
});

// ---------------------------------------------------------------------------
// PATCH /api/addresses/:id/default — Set address as primary default
// ---------------------------------------------------------------------------
router.patch('/:id/default', async (req: Request, res: Response) => {
  try {
    const customerId = req.user!.id;
    const addressId = parseInt(String(req.params.id), 10);
    if (isNaN(addressId)) {
      return res.status(400).json({ error: 'Invalid address ID.' });
    }

    const existing = await prisma.address.findUnique({
      where: { id: addressId },
    });

    if (!existing || existing.userId !== customerId) {
      return res.status(404).json({ error: 'Address not found.' });
    }

    const result = await prisma.$transaction(async (tx) => {
      await tx.address.updateMany({
        where: { userId: customerId, isDefault: true },
        data: { isDefault: false },
      });

      return tx.address.update({
        where: { id: addressId },
        data: { isDefault: true },
      });
    });

    return res.json(result);
  } catch (error: unknown) {
    console.error('Error setting default address:', error);
    return res.status(500).json({ error: 'Failed to set default address.' });
  }
});

// ---------------------------------------------------------------------------
// DELETE /api/addresses/:id — Delete an address
// ---------------------------------------------------------------------------
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const customerId = req.user!.id;
    const addressId = parseInt(String(req.params.id), 10);
    if (isNaN(addressId)) {
      return res.status(400).json({ error: 'Invalid address ID.' });
    }

    const existing = await prisma.address.findUnique({
      where: { id: addressId },
    });

    if (!existing || existing.userId !== customerId) {
      return res.status(404).json({ error: 'Address not found.' });
    }

    await prisma.$transaction(async (tx) => {
      await tx.address.delete({
        where: { id: addressId },
      });

      // If we deleted the default address, promote the most recent remaining address
      if (existing.isDefault) {
        const nextDefault = await tx.address.findFirst({
          where: { userId: customerId },
          orderBy: { createdAt: 'desc' },
        });
        if (nextDefault) {
          await tx.address.update({
            where: { id: nextDefault.id },
            data: { isDefault: true },
          });
        }
      }
    });

    return res.json({ message: 'Address deleted successfully.' });
  } catch (error: unknown) {
    console.error('Error deleting address:', error);
    return res.status(500).json({ error: 'Failed to delete address.' });
  }
});

export default router;
