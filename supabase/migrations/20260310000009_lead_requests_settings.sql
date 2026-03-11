-- Migration 9: lead_requests, lead_events, user_settings, delete_requests

-- ── Lead Requests (state machine) ──
CREATE TABLE IF NOT EXISTS public.lead_requests (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  agent_id      text NOT NULL,
  message       text DEFAULT '',
  channel_pref  text NOT NULL DEFAULT 'in_app'
                CHECK (channel_pref IN ('email','phone','in_app')),
  urgency       text NOT NULL DEFAULT 'medium'
                CHECK (urgency IN ('low','medium','high')),
  callback_time text DEFAULT NULL,
  consent_reveal_contact boolean NOT NULL DEFAULT false,
  attachment_url text DEFAULT NULL,
  status        text NOT NULL DEFAULT 'requested'
                CHECK (status IN (
                  'requested','viewed','need_more_info','quoting',
                  'quote_sent','closed_won','closed_lost','archived'
                )),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.lead_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own leads" ON public.lead_requests
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_lead_requests_user ON public.lead_requests(user_id, status);
CREATE INDEX idx_lead_requests_agent ON public.lead_requests(agent_id, status);

-- ── Lead Events (audit trail) ──
CREATE TABLE IF NOT EXISTS public.lead_events (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_request_id uuid NOT NULL REFERENCES public.lead_requests(id) ON DELETE CASCADE,
  event_type      text NOT NULL,
  metadata        jsonb DEFAULT '{}',
  created_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.lead_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own lead events" ON public.lead_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.lead_requests lr
      WHERE lr.id = lead_request_id AND lr.user_id = auth.uid()
    )
  );

CREATE INDEX idx_lead_events_request ON public.lead_events(lead_request_id);

-- ── User Settings ──
CREATE TABLE IF NOT EXISTS public.user_settings (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_email  boolean NOT NULL DEFAULT true,
  notification_push   boolean NOT NULL DEFAULT true,
  quiet_hours_start   time DEFAULT NULL,
  quiet_hours_end     time DEFAULT NULL,
  data_sharing        boolean NOT NULL DEFAULT true,
  blocked_agents      text[] DEFAULT '{}',
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own settings" ON public.user_settings
  FOR ALL USING (auth.uid() = user_id);

-- ── Delete Requests ──
CREATE TABLE IF NOT EXISTS public.delete_requests (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status        text NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','scheduled','completed','cancelled')),
  reason        text DEFAULT '',
  requested_at  timestamptz NOT NULL DEFAULT now(),
  scheduled_at  timestamptz DEFAULT (now() + interval '30 days'),
  completed_at  timestamptz DEFAULT NULL
);

ALTER TABLE public.delete_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own delete requests" ON public.delete_requests
  FOR ALL USING (auth.uid() = user_id);
