ALTER TABLE "OrderChatMessage" ADD COLUMN "channel" TEXT NOT NULL DEFAULT 'customer_partner', ADD COLUMN "driverProfileId" INTEGER;
CREATE INDEX "OrderChatMessage_orderId_channel_driverProfileId_idx" ON "OrderChatMessage"("orderId", "channel", "driverProfileId");
