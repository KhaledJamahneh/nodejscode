
# Database Schema Documentation

**Generated:** 2026-03-01  
**Database:** Einhod Water Management System  
**Total Tables:** 34

---

=== DATABASE SCHEMA ===


📋 ANNOUNCEMENTS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('announcements_id_seq'::regclass)
  title                          character varying(255) NOT NULL
  content                        text                 NOT NULL
  image_url                      text                 NULL
  external_link                  text                 NULL
  created_by                     integer              NULL
  is_active                      boolean              NULL DEFAULT true
  start_date                     date                 NULL
  end_date                       date                 NULL
  view_count                     integer              NULL DEFAULT 0
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 APOLOGY_MESSAGES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('apology_messages_id_seq'::regclass)
  worker_id                      integer              NULL
  client_id                      integer              NULL
  delivery_request_id            integer              NULL
  message_template               text                 NOT NULL
  sent_at                        timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 AUDIT_LOG
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('audit_log_id_seq'::regclass)
  user_id                        integer              NULL
  action                         character varying(100) NOT NULL
  table_name                     character varying(100) NULL
  record_id                      integer              NULL
  old_values                     jsonb                NULL
  new_values                     jsonb                NULL
  ip_address                     inet                 NULL
  user_agent                     text                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 CLIENT_ASSETS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('client_assets_id_seq'::regclass)
  client_id                      integer              NULL
  dispenser_id                   integer              NULL
  asset_type                     character varying(50) NULL
  quantity                       integer              NULL DEFAULT 1
  assigned_date                  date                 NOT NULL
  returned_date                  date                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 CLIENT_PROFILES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('client_profiles_id_seq'::regclass)
  user_id                        integer              NULL
  full_name                      character varying(255) NOT NULL
  address                        text                 NOT NULL
  latitude                       numeric              NULL
  longitude                      numeric              NULL
  subscription_type              USER-DEFINED         NOT NULL
  subscription_start_date        date                 NULL
  subscription_end_date          date                 NULL
  subscription_expiry_date       date                 NULL
  remaining_coupons              integer              NULL DEFAULT 0
  monthly_usage_gallons          numeric              NULL DEFAULT 0
  current_debt                   numeric              NULL DEFAULT 0
  preferred_language             character varying(10) NULL DEFAULT 'en'::character varying
  proximity_notifications_enabled boolean              NULL DEFAULT true
  home_latitude                  numeric              NULL
  home_longitude                 numeric              NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  coupon_book_size_id            integer              NULL
  gallons_on_hand                integer              NULL DEFAULT 0

📋 COUPON_BOOK_REQUESTS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('coupon_book_requests_id_seq'::regclass)
  client_id                      integer              NULL
  requested_at                   timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  status                         character varying(20) NULL DEFAULT 'pending'::character varying
  processed_at                   timestamp without time zone NULL
  processed_by                   integer              NULL
  notes                          text                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  book_type                      character varying(50) NULL
  total_price                    numeric              NULL
  payment_method                 character varying(50) NULL
  coupon_size_id                 integer              NULL

📋 COUPON_SIZES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('coupon_sizes_id_seq'::regclass)
  size                           integer              NOT NULL
  price                          numeric              NOT NULL
  is_active                      boolean              NULL DEFAULT true
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  price_per_page                 numeric              NULL
  bonus_gallons                  integer              NULL DEFAULT 0
  expiry_days                    integer              NULL DEFAULT 365

📋 DELIVERIES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('deliveries_id_seq'::regclass)
  client_id                      integer              NULL
  worker_id                      integer              NULL
  delivery_date                  date                 NOT NULL
  scheduled_time                 time without time zone NULL
  actual_delivery_time           timestamp without time zone NULL
  gallons_delivered              integer              NOT NULL
  delivery_latitude              numeric              NULL
  delivery_longitude             numeric              NULL
  status                         USER-DEFINED         NULL DEFAULT 'pending'::delivery_status
  notes                          text                 NULL
  photo_url                      text                 NULL
  is_main_list                   boolean              NULL DEFAULT true
  request_id                     integer              NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  empty_gallons_returned         integer              NULL DEFAULT 0
  paid_amount                    numeric              NULL DEFAULT 0
  total_price                    numeric              NULL DEFAULT 0

📋 DELIVERY_REQUESTS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('delivery_requests_id_seq'::regclass)
  client_id                      integer              NULL
  priority                       USER-DEFINED         NULL DEFAULT 'non_urgent'::delivery_priority
  requested_gallons              integer              NOT NULL
  request_date                   timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  status                         USER-DEFINED         NULL DEFAULT 'pending'::delivery_status
  assigned_worker_id             integer              NULL
  notes                          text                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  payment_method                 USER-DEFINED         NULL DEFAULT 'cash'::payment_method

📋 DISPENSER_DELIVERIES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('dispenser_deliveries_id_seq'::regclass)
  delivery_id                    integer              NULL
  dispenser_id                   integer              NULL
  condition                      USER-DEFINED         NULL
  photo_url                      text                 NULL
  delivery_latitude              numeric              NULL
  delivery_longitude             numeric              NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 DISPENSER_FEATURES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('dispenser_features_id_seq'::regclass)
  name                           character varying(100) NOT NULL
  display_order                  integer              NULL DEFAULT 0
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 DISPENSER_MAINTENANCE
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('dispenser_maintenance_id_seq'::regclass)
  dispenser_id                   integer              NULL
  maintenance_date               date                 NOT NULL
  description                    text                 NULL
  cost                           numeric              NULL
  performed_by                   integer              NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 DISPENSER_TYPES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('dispenser_types_id_seq'::regclass)
  name                           character varying(100) NOT NULL
  description                    text                 NULL
  display_order                  integer              NULL DEFAULT 0
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 DISPENSERS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('dispensers_id_seq'::regclass)
  serial_number                  character varying(100) NOT NULL
  dispenser_type                 USER-DEFINED         NOT NULL
  status                         USER-DEFINED         NULL DEFAULT 'new'::dispenser_status
  purchase_date                  date                 NOT NULL
  purchase_price                 numeric              NULL
  current_location_type          character varying(20) NULL DEFAULT 'warehouse'::character varying
  current_client_id              integer              NULL
  image_url                      text                 NULL
  notes                          text                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  type_id                        integer              NULL
  features                       ARRAY                NULL DEFAULT '{}'::text[]

📋 EXPENSE_CATEGORIES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('expense_categories_id_seq'::regclass)
  name                           character varying(100) NOT NULL
  description                    text                 NULL

📋 EXPENSES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('expenses_id_seq'::regclass)
  worker_id                      integer              NULL
  amount                         numeric              NOT NULL
  description                    text                 NOT NULL
  merchant_name                  character varying(255) NULL
  expense_date                   date                 NOT NULL
  payment_method                 USER-DEFINED         NOT NULL
  status                         USER-DEFINED         NULL DEFAULT 'pending'::expense_status
  receipt_photo_url              text                 NULL
  approved_by                    integer              NULL
  approval_date                  timestamp without time zone NULL
  admin_notes                    text                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  category_id                    integer              NULL

📋 FILLING_SESSIONS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('filling_sessions_id_seq'::regclass)
  station_id                     integer              NULL
  worker_id                      integer              NULL
  gallons_filled                 integer              NOT NULL
  session_number                 integer              NULL
  start_time                     timestamp without time zone NULL
  completion_time                timestamp without time zone NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 FILLING_STATIONS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('filling_stations_id_seq'::regclass)
  name                           character varying(255) NOT NULL
  latitude                       numeric              NULL
  longitude                      numeric              NULL
  address                        text                 NULL
  current_status                 USER-DEFINED         NULL DEFAULT 'open'::station_status
  manager_id                     integer              NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 GPS_LOCATIONS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('gps_locations_id_seq'::regclass)
  worker_id                      integer              NULL
  latitude                       numeric              NOT NULL
  longitude                      numeric              NOT NULL
  recorded_at                    timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  accuracy_meters                numeric              NULL
  speed_kmh                      numeric              NULL

📋 JOB_DESCRIPTIONS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('job_descriptions_id_seq'::regclass)
  worker_id                      integer              NULL
  title                          character varying(255) NOT NULL
  responsibilities               text                 NOT NULL
  fixed_salary                   numeric              NULL
  version                        integer              NULL DEFAULT 1
  created_by                     integer              NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  approved_by_worker             boolean              NULL DEFAULT false
  worker_approval_date           timestamp without time zone NULL
  is_active                      boolean              NULL DEFAULT false

📋 NOTIFICATIONS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('notifications_id_seq'::regclass)
  user_id                        integer              NULL
  title                          character varying(255) NOT NULL
  message                        text                 NOT NULL
  category                       USER-DEFINED         NULL DEFAULT 'normal'::notification_category
  is_read                        boolean              NULL DEFAULT false
  action_url                     text                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  read_at                        timestamp without time zone NULL
  type                           character varying(50) NOT NULL
  reference_id                   integer              NULL
  reference_type                 character varying(50) NULL

📋 PAYMENTS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('payments_id_seq'::regclass)
  payer_id                       integer              NULL
  receiver_type                  character varying(20) NULL DEFAULT 'company'::character varying
  receiver_id                    integer              NULL
  amount                         numeric              NOT NULL
  payment_method                 USER-DEFINED         NOT NULL
  payment_status                 USER-DEFINED         NULL DEFAULT 'pending'::payment_status
  transaction_id                 character varying(255) NULL
  payment_gateway_response       jsonb                NULL
  payment_date                   timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  description                    text                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 SCHEDULED_DELIVERIES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('scheduled_deliveries_id_seq'::regclass)
  client_id                      integer              NOT NULL
  worker_id                      integer              NULL
  gallons                        integer              NOT NULL
  schedule_type                  character varying(20) NOT NULL
  schedule_time                  time without time zone NOT NULL
  schedule_days                  ARRAY                NULL
  start_date                     date                 NOT NULL DEFAULT CURRENT_DATE
  end_date                       date                 NULL
  is_active                      boolean              NULL DEFAULT true
  notes                          text                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 SOCIAL_MEDIA_POSTS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('social_media_posts_id_seq'::regclass)
  worker_id                      integer              NULL
  platform                       character varying(50) NOT NULL
  topic                          character varying(255) NOT NULL
  post_link                      text                 NULL
  post_date                      date                 NOT NULL
  engagement_count               integer              NULL DEFAULT 0
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 SYSTEM_SETTINGS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('system_settings_id_seq'::regclass)
  setting_key                    character varying(100) NOT NULL
  setting_value                  text                 NULL
  description                    text                 NULL
  updated_by                     integer              NULL
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 UNIFORM_DISTRIBUTIONS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('uniform_distributions_id_seq'::regclass)
  worker_id                      integer              NULL
  item_type                      character varying(100) NOT NULL
  quantity                       integer              NOT NULL
  distribution_date              date                 NOT NULL
  size                           character varying(20) NULL
  distributed_by                 integer              NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 USERS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('users_id_seq'::regclass)
  username                       character varying(50) NOT NULL
  email                          character varying(255) NULL
  phone_number                   character varying(20) NOT NULL
  password_hash                  character varying(255) NOT NULL
  role                           ARRAY                NOT NULL
  is_active                      boolean              NULL DEFAULT true
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  last_login                     timestamp without time zone NULL

📋 WORK_SHIFTS
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('work_shifts_id_seq'::regclass)
  name                           character varying(100) NOT NULL
  days_of_week                   ARRAY                NOT NULL
  start_time                     time without time zone NOT NULL
  end_time                       time without time zone NOT NULL
  is_active                      boolean              NULL DEFAULT true
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 WORKER_EXPENSES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('worker_expenses_id_seq'::regclass)
  user_id                        integer              NULL
  amount                         numeric              NOT NULL
  payment_method                 character varying(50) NULL
  payment_status                 character varying(50) NULL DEFAULT 'pending'::character varying
  destination                    character varying(255) NULL
  notes                          text                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 WORKER_LEAVES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('worker_leaves_id_seq'::regclass)
  user_id                        integer              NOT NULL
  leave_type                     USER-DEFINED         NOT NULL
  start_date                     date                 NOT NULL
  end_date                       date                 NOT NULL
  reason                         text                 NULL
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP

📋 WORKER_PROFILES
────────────────────────────────────────────────────────────────────────────────
  id                             integer              NOT NULL DEFAULT nextval('worker_profiles_id_seq'::regclass)
  user_id                        integer              NULL
  full_name                      character varying(255) NOT NULL
  worker_type                    character varying(50) NOT NULL
  hire_date                      date                 NOT NULL
  current_salary                 numeric              NULL
  debt_advances                  numeric              NULL DEFAULT 0
  vehicle_current_gallons        integer              NULL DEFAULT 0
  gps_sharing_enabled            boolean              NULL DEFAULT false
  is_dual_role                   boolean              NULL DEFAULT false
  created_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  updated_at                     timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP
  shift_id                       integer              NULL
  vehicle_capacity               integer              NULL DEFAULT 1000
  preferred_language             character varying(10) NULL DEFAULT 'en'::character varying
