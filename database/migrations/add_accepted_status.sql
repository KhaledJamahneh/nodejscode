-- Add 'accepted' status to delivery_status enum
ALTER TYPE delivery_status ADD VALUE IF NOT EXISTS 'accepted' AFTER 'pending';
