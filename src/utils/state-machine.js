/**
 * Valid status transitions for the system entities
 */

const DELIVERY_TRANSITIONS = {
  'pending': ['in_progress', 'cancelled'],
  'in_progress': ['completed', 'cancelled'],
  'completed': ['in_progress'], // Allow admin to revert if needed
  'cancelled': []  // Terminal state
};

const REQUEST_TRANSITIONS = {
  'pending': ['in_progress', 'cancelled'],
  'in_progress': ['completed', 'cancelled'],
  'completed': [], // Terminal state
  'cancelled': []  // Terminal state
};

const COUPON_BOOK_REQUEST_TRANSITIONS = {
  'pending': ['approved', 'assigned', 'cancelled'],
  'approved': ['assigned', 'in_progress', 'cancelled'],
  'assigned': ['in_progress', 'completed', 'cancelled'],
  'in_progress': ['completed', 'cancelled'],
  'completed': [], // Terminal state
  'cancelled': []  // Terminal state
};

/**
 * Validates a status transition
 * @param {string} type - 'delivery', 'request', or 'coupon_request'
 * @param {string} currentStatus - Current status in database
 * @param {string} nextStatus - New status being requested
 * @returns {boolean} - True if transition is valid
 */
const isValidTransition = (type, currentStatus, nextStatus) => {
  // If status is the same, it's technically valid (noop)
  if (currentStatus === nextStatus) return true;

  let transitions;
  switch (type) {
    case 'delivery':
      transitions = DELIVERY_TRANSITIONS;
      break;
    case 'request':
      transitions = REQUEST_TRANSITIONS;
      break;
    case 'coupon_request':
      transitions = COUPON_BOOK_REQUEST_TRANSITIONS;
      break;
    default:
      return false;
  }

  const allowed = transitions[currentStatus] || [];
  return allowed.includes(nextStatus);
};

module.exports = {
  isValidTransition,
  DELIVERY_TRANSITIONS,
  REQUEST_TRANSITIONS,
  COUPON_BOOK_REQUEST_TRANSITIONS
};
