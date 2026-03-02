-- Add notification_key and params for localization
ALTER TABLE notifications 
ADD COLUMN notification_key VARCHAR(100),
ADD COLUMN params JSONB DEFAULT '{}';

-- Update existing notifications with keys (best effort mapping)
UPDATE notifications SET notification_key = 'notification.delivery.assigned' WHERE title = 'New Task Assigned';
UPDATE notifications SET notification_key = 'notification.request.accepted' WHERE title = 'Request Accepted';
UPDATE notifications SET notification_key = 'notification.delivery.completed' WHERE title = 'Delivery Completed';
UPDATE notifications SET notification_key = 'notification.payment.received' WHERE title = 'Payment Received';
UPDATE notifications SET notification_key = 'notification.worker.nearby' WHERE title LIKE '%is nearby%';

-- For any remaining notifications without a key, use a generic key
UPDATE notifications SET notification_key = 'notification.generic' WHERE notification_key IS NULL;
