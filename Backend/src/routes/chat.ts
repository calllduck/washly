import { Router, Request, Response } from 'express';
import { prisma } from '../config/prisma.js';
import { authGuard } from '../middleware/authGuard.js';

const router = Router();
router.use(authGuard);

function isNonEmptyString(v: unknown): v is string {
  return typeof v === 'string' && v.trim().length > 0;
}

// ---------------------------------------------------------------------------
// GET /api/chat/orders/:orderId/messages — Get message thread for an order
// ---------------------------------------------------------------------------
router.get('/orders/:orderId/messages', async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const orderId = parseInt(String(req.params.orderId), 10);
    if (isNaN(orderId)) {
      return res.status(400).json({ error: 'Invalid order ID.' });
    }

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: {
        laundromat: { select: { id: true, ownerId: true, name: true, imageUrl: true } },
        customer: { select: { id: true, name: true } },
      },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found.' });
    }

    const isCustomer = order.customerId === userId;
    const isPartner = order.laundromat.ownerId === userId;

    if (!isCustomer && !isPartner) {
      return res.status(403).json({ error: 'You are not authorized to view this chat.' });
    }

    const sinceId = req.query.sinceId ? parseInt(String(req.query.sinceId), 10) : undefined;

    const messages = await prisma.orderChatMessage.findMany({
      where: {
        orderId,
        ...(sinceId && !isNaN(sinceId) ? { id: { gt: sinceId } } : {}),
      },
      include: {
        sender: { select: { id: true, name: true, role: true } },
      },
      orderBy: { createdAt: 'asc' },
    });

    // Mark messages from the other side as read
    const otherRole = isCustomer ? 'PARTNER' : 'CUSTOMER';
    await prisma.orderChatMessage.updateMany({
      where: {
        orderId,
        senderRole: otherRole,
        isRead: false,
      },
      data: { isRead: true },
    });

    return res.json({
      order: {
        id: order.id,
        status: order.status,
        storeName: order.laundromat.name,
        storeImageUrl: order.laundromat.imageUrl,
        customerName: order.customer.name,
      },
      messages: messages.map((m) => ({
        id: m.id,
        orderId: m.orderId,
        senderId: m.senderId,
        senderRole: m.senderRole,
        senderName: m.sender.name,
        text: m.text,
        isRead: m.isRead,
        isMine: m.senderId === userId,
        createdAt: m.createdAt,
      })),
    });
  } catch (error: unknown) {
    console.error('Error fetching chat messages:', error);
    return res.status(500).json({ error: 'Failed to fetch chat messages.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/chat/orders/:orderId/messages — Send a message in an order chat
// ---------------------------------------------------------------------------
router.post('/orders/:orderId/messages', async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const orderId = parseInt(String(req.params.orderId), 10);
    if (isNaN(orderId)) {
      return res.status(400).json({ error: 'Invalid order ID.' });
    }

    const { text } = req.body ?? {};
    if (!isNonEmptyString(text)) {
      return res.status(400).json({ error: 'Pesan tidak boleh kosong.' });
    }

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: {
        laundromat: { select: { ownerId: true } },
      },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found.' });
    }

    const isCustomer = order.customerId === userId;
    const isPartner = order.laundromat.ownerId === userId;

    if (!isCustomer && !isPartner) {
      return res.status(403).json({ error: 'You are not authorized to send messages in this order.' });
    }

    const senderRole = isCustomer ? 'CUSTOMER' : 'PARTNER';

    const message = await prisma.orderChatMessage.create({
      data: {
        orderId,
        senderId: userId,
        senderRole,
        text: text.trim(),
        isRead: false,
      },
      include: {
        sender: { select: { id: true, name: true, role: true } },
      },
    });

    return res.status(201).json({
      id: message.id,
      orderId: message.orderId,
      senderId: message.senderId,
      senderRole: message.senderRole,
      senderName: message.sender.name,
      text: message.text,
      isRead: message.isRead,
      isMine: true,
      createdAt: message.createdAt,
    });
  } catch (error: unknown) {
    console.error('Error sending chat message:', error);
    return res.status(500).json({ error: 'Failed to send chat message.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/chat/orders/:orderId/unread — Check unread messages count
// ---------------------------------------------------------------------------
router.get('/orders/:orderId/unread', async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const orderId = parseInt(String(req.params.orderId), 10);
    if (isNaN(orderId)) {
      return res.status(400).json({ error: 'Invalid order ID.' });
    }

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { laundromat: { select: { ownerId: true } } },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found.' });
    }

    const isCustomer = order.customerId === userId;
    const isPartner = order.laundromat.ownerId === userId;

    if (!isCustomer && !isPartner) {
      return res.status(403).json({ error: 'Unauthorized.' });
    }

    const otherRole = isCustomer ? 'PARTNER' : 'CUSTOMER';
    const unreadCount = await prisma.orderChatMessage.count({
      where: {
        orderId,
        senderRole: otherRole,
        isRead: false,
      },
    });

    return res.json({ unreadCount });
  } catch (error: unknown) {
    console.error('Error fetching unread count:', error);
    return res.status(500).json({ error: 'Failed to fetch unread count.' });
  }
});

export default router;
