SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: prevent_modification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_modification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'table % is append-only and cannot be modified', TG_TABLE_NAME;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_events (
    id bigint NOT NULL,
    user_id bigint,
    action character varying NOT NULL,
    subject_type character varying,
    subject_id bigint,
    ip_hash character varying,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT audit_events_action_present CHECK ((char_length((action)::text) > 0))
);


--
-- Name: audit_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_events_id_seq OWNED BY public.audit_events.id;


--
-- Name: consent_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consent_records (
    id bigint NOT NULL,
    subject_token character varying NOT NULL,
    kind character varying NOT NULL,
    granted_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone,
    policy_version character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT consent_records_kind_known CHECK (((kind)::text = ANY ((ARRAY['analytics'::character varying, 'marketing'::character varying, 'cookies'::character varying, 'terms'::character varying])::text[]))),
    CONSTRAINT consent_records_revocation_after_grant CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at)))
);


--
-- Name: consent_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.consent_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consent_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.consent_records_id_seq OWNED BY public.consent_records.id;


--
-- Name: data_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_requests (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    kind character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    requested_at timestamp(6) without time zone NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT data_requests_completed_has_timestamp CHECK ((((status)::text <> 'completed'::text) OR (completed_at IS NOT NULL))),
    CONSTRAINT data_requests_kind_known CHECK (((kind)::text = ANY ((ARRAY['export'::character varying, 'deletion'::character varying])::text[]))),
    CONSTRAINT data_requests_status_known CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'processing'::character varying, 'completed'::character varying, 'rejected'::character varying])::text[])))
);


--
-- Name: data_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_requests_id_seq OWNED BY public.data_requests.id;


--
-- Name: generation_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generation_batches (
    id bigint NOT NULL,
    genre_id bigint NOT NULL,
    created_by_id bigint,
    name character varying NOT NULL,
    prompt_style text NOT NULL,
    lyrics text,
    cot character varying DEFAULT 'off'::character varying NOT NULL,
    steps integer DEFAULT 32 NOT NULL,
    requested_count integer DEFAULT 1 NOT NULL,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT generation_batches_cot_known CHECK (((cot)::text = ANY ((ARRAY['off'::character varying, 'melody'::character varying, 'full'::character varying])::text[]))),
    CONSTRAINT generation_batches_count_positive CHECK ((requested_count > 0)),
    CONSTRAINT generation_batches_name_present CHECK ((char_length((name)::text) > 0)),
    CONSTRAINT generation_batches_prompt_present CHECK ((char_length(prompt_style) > 0)),
    CONSTRAINT generation_batches_status_known CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'queued'::character varying, 'running'::character varying, 'completed'::character varying, 'canceled'::character varying])::text[]))),
    CONSTRAINT generation_batches_steps_positive CHECK ((steps > 0))
);


--
-- Name: generation_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.generation_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: generation_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.generation_batches_id_seq OWNED BY public.generation_batches.id;


--
-- Name: generation_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generation_runs (
    id bigint NOT NULL,
    generation_batch_id bigint NOT NULL,
    track_id bigint,
    status character varying DEFAULT 'queued'::character varying NOT NULL,
    comfy_prompt_id character varying,
    seed bigint,
    error text,
    started_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    duration_ms integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT generation_runs_duration_non_negative CHECK (((duration_ms IS NULL) OR (duration_ms >= 0))),
    CONSTRAINT generation_runs_failed_has_error CHECK ((((status)::text <> 'failed'::text) OR (error IS NOT NULL))),
    CONSTRAINT generation_runs_status_known CHECK (((status)::text = ANY ((ARRAY['queued'::character varying, 'running'::character varying, 'succeeded'::character varying, 'failed'::character varying, 'canceled'::character varying])::text[]))),
    CONSTRAINT generation_runs_times_ordered CHECK (((finished_at IS NULL) OR (started_at IS NULL) OR (finished_at >= started_at)))
);


--
-- Name: generation_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.generation_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: generation_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.generation_runs_id_seq OWNED BY public.generation_runs.id;


--
-- Name: genre_entitlements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genre_entitlements (
    id bigint NOT NULL,
    subscription_id bigint NOT NULL,
    genre_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: genre_entitlements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.genre_entitlements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genre_entitlements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.genre_entitlements_id_seq OWNED BY public.genre_entitlements.id;


--
-- Name: genres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genres (
    id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    "position" integer DEFAULT 0 NOT NULL,
    published boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT genres_name_present CHECK ((char_length((name)::text) > 0)),
    CONSTRAINT genres_slug_format CHECK (((slug)::text ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text))
);


--
-- Name: genres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.genres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.genres_id_seq OWNED BY public.genres.id;


--
-- Name: newsletter_subscribers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.newsletter_subscribers (
    id bigint NOT NULL,
    email character varying NOT NULL,
    confirmed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT newsletter_subscribers_email_shape CHECK (((email)::text ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'::text))
);


--
-- Name: newsletter_subscribers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.newsletter_subscribers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: newsletter_subscribers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.newsletter_subscribers_id_seq OWNED BY public.newsletter_subscribers.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    plan_id bigint NOT NULL,
    number character varying NOT NULL,
    public_token character varying NOT NULL,
    amount_cents integer NOT NULL,
    currency character varying DEFAULT 'USD'::character varying NOT NULL,
    status character varying DEFAULT 'awaiting_payment'::character varying NOT NULL,
    provider character varying,
    provider_order_id character varying,
    provider_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    placed_at timestamp(6) without time zone NOT NULL,
    paid_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT orders_amount_positive CHECK ((amount_cents > 0)),
    CONSTRAINT orders_currency_iso CHECK (((currency)::text ~ '^[A-Z]{3}$'::text)),
    CONSTRAINT orders_paid_has_timestamp CHECK ((((status)::text <> 'paid'::text) OR (paid_at IS NOT NULL))),
    CONSTRAINT orders_public_token_long_enough CHECK ((char_length((public_token)::text) >= 24)),
    CONSTRAINT orders_status_known CHECK (((status)::text = ANY ((ARRAY['awaiting_payment'::character varying, 'paid'::character varying, 'refunded'::character varying, 'canceled'::character varying])::text[])))
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages (
    id bigint NOT NULL,
    slug character varying NOT NULL,
    title character varying NOT NULL,
    body text,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT pages_status_known CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'published'::character varying])::text[])))
);


--
-- Name: pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pages_id_seq OWNED BY public.pages.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    price_cents integer NOT NULL,
    currency character varying DEFAULT 'USD'::character varying NOT NULL,
    "interval" character varying DEFAULT 'month'::character varying NOT NULL,
    genre_limit integer NOT NULL,
    features jsonb DEFAULT '{}'::jsonb NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT plans_currency_iso CHECK (((currency)::text ~ '^[A-Z]{3}$'::text)),
    CONSTRAINT plans_genre_limit_positive CHECK ((genre_limit > 0)),
    CONSTRAINT plans_interval_known CHECK ((("interval")::text = ANY ((ARRAY['month'::character varying, 'year'::character varying])::text[]))),
    CONSTRAINT plans_name_present CHECK ((char_length((name)::text) > 0)),
    CONSTRAINT plans_price_positive CHECK ((price_cents > 0)),
    CONSTRAINT plans_slug_format CHECK (((slug)::text ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text))
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id bigint NOT NULL,
    slug character varying NOT NULL,
    title character varying NOT NULL,
    excerpt character varying,
    body text,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    published_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT posts_published_has_timestamp CHECK ((((status)::text <> 'published'::text) OR (published_at IS NOT NULL))),
    CONSTRAINT posts_status_known CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'published'::character varying])::text[])))
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: redirects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.redirects (
    id bigint NOT NULL,
    from_path character varying NOT NULL,
    to_path character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT redirects_paths_absolute CHECK ((((from_path)::text ~~ '/%'::text) AND ((to_path)::text ~~ '/%'::text)))
);


--
-- Name: redirects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.redirects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redirects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.redirects_id_seq OWNED BY public.redirects.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: subscription_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscription_events (
    id bigint NOT NULL,
    subscription_id bigint NOT NULL,
    kind character varying NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT subscription_events_kind_known CHECK (((kind)::text = ANY ((ARRAY['created'::character varying, 'activated'::character varying, 'plan_changed'::character varying, 'genre_added'::character varying, 'genre_removed'::character varying, 'renewed'::character varying, 'past_due'::character varying, 'canceled'::character varying, 'reactivated'::character varying])::text[])))
);


--
-- Name: subscription_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscription_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscription_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscription_events_id_seq OWNED BY public.subscription_events.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    plan_id bigint NOT NULL,
    status character varying DEFAULT 'incomplete'::character varying NOT NULL,
    current_period_start timestamp(6) without time zone,
    current_period_end timestamp(6) without time zone,
    canceled_at timestamp(6) without time zone,
    provider character varying,
    provider_subscription_id character varying,
    provider_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT subscriptions_canceled_has_status CHECK (((canceled_at IS NULL) OR ((status)::text = 'canceled'::text))),
    CONSTRAINT subscriptions_period_ordered CHECK (((current_period_end IS NULL) OR (current_period_start IS NULL) OR (current_period_end > current_period_start))),
    CONSTRAINT subscriptions_status_known CHECK (((status)::text = ANY ((ARRAY['incomplete'::character varying, 'active'::character varying, 'past_due'::character varying, 'canceled'::character varying])::text[])))
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: track_downloads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.track_downloads (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    track_id bigint NOT NULL,
    license_terms_version character varying NOT NULL,
    ip_hash character varying,
    created_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT track_downloads_license_version_present CHECK ((char_length((license_terms_version)::text) > 0))
);


--
-- Name: track_downloads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.track_downloads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: track_downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.track_downloads_id_seq OWNED BY public.track_downloads.id;


--
-- Name: tracks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracks (
    id bigint NOT NULL,
    genre_id bigint NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    artist_name character varying,
    duration_ms integer,
    bpm integer,
    musical_key character varying,
    mood character varying,
    language character varying,
    lyrics text,
    abc_score text,
    prompt_style text,
    model_id character varying,
    seed bigint,
    downloadable boolean DEFAULT true NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    published_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    CONSTRAINT tracks_bpm_sane CHECK (((bpm IS NULL) OR ((bpm >= 20) AND (bpm <= 400)))),
    CONSTRAINT tracks_duration_positive CHECK (((duration_ms IS NULL) OR (duration_ms > 0))),
    CONSTRAINT tracks_published_has_timestamp CHECK ((((status)::text <> 'published'::text) OR (published_at IS NOT NULL))),
    CONSTRAINT tracks_slug_format CHECK (((slug)::text ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text)),
    CONSTRAINT tracks_status_known CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'published'::character varying, 'archived'::character varying])::text[]))),
    CONSTRAINT tracks_title_present CHECK ((char_length((title)::text) > 0))
);


--
-- Name: tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tracks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tracks_id_seq OWNED BY public.tracks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    terms_accepted_at timestamp(6) without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp(6) without time zone,
    last_sign_in_at timestamp(6) without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    CONSTRAINT users_name_present CHECK ((char_length((name)::text) > 0)),
    CONSTRAINT users_role_known CHECK (((role)::text = ANY ((ARRAY['member'::character varying, 'editor'::character varying, 'admin'::character varying])::text[])))
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    whodunnit character varying,
    created_at timestamp(6) without time zone,
    item_id bigint NOT NULL,
    item_type character varying NOT NULL,
    event character varying NOT NULL,
    object text
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: audit_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events ALTER COLUMN id SET DEFAULT nextval('public.audit_events_id_seq'::regclass);


--
-- Name: consent_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consent_records ALTER COLUMN id SET DEFAULT nextval('public.consent_records_id_seq'::regclass);


--
-- Name: data_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_requests ALTER COLUMN id SET DEFAULT nextval('public.data_requests_id_seq'::regclass);


--
-- Name: generation_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_batches ALTER COLUMN id SET DEFAULT nextval('public.generation_batches_id_seq'::regclass);


--
-- Name: generation_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_runs ALTER COLUMN id SET DEFAULT nextval('public.generation_runs_id_seq'::regclass);


--
-- Name: genre_entitlements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genre_entitlements ALTER COLUMN id SET DEFAULT nextval('public.genre_entitlements_id_seq'::regclass);


--
-- Name: genres id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genres ALTER COLUMN id SET DEFAULT nextval('public.genres_id_seq'::regclass);


--
-- Name: newsletter_subscribers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.newsletter_subscribers ALTER COLUMN id SET DEFAULT nextval('public.newsletter_subscribers_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages ALTER COLUMN id SET DEFAULT nextval('public.pages_id_seq'::regclass);


--
-- Name: plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: redirects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.redirects ALTER COLUMN id SET DEFAULT nextval('public.redirects_id_seq'::regclass);


--
-- Name: subscription_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_events ALTER COLUMN id SET DEFAULT nextval('public.subscription_events_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: track_downloads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.track_downloads ALTER COLUMN id SET DEFAULT nextval('public.track_downloads_id_seq'::regclass);


--
-- Name: tracks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracks ALTER COLUMN id SET DEFAULT nextval('public.tracks_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audit_events audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);


--
-- Name: consent_records consent_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consent_records
    ADD CONSTRAINT consent_records_pkey PRIMARY KEY (id);


--
-- Name: data_requests data_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_requests
    ADD CONSTRAINT data_requests_pkey PRIMARY KEY (id);


--
-- Name: generation_batches generation_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_batches
    ADD CONSTRAINT generation_batches_pkey PRIMARY KEY (id);


--
-- Name: generation_runs generation_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_runs
    ADD CONSTRAINT generation_runs_pkey PRIMARY KEY (id);


--
-- Name: genre_entitlements genre_entitlements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genre_entitlements
    ADD CONSTRAINT genre_entitlements_pkey PRIMARY KEY (id);


--
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (id);


--
-- Name: newsletter_subscribers newsletter_subscribers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.newsletter_subscribers
    ADD CONSTRAINT newsletter_subscribers_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: pages pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: redirects redirects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.redirects
    ADD CONSTRAINT redirects_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: subscription_events subscription_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_events
    ADD CONSTRAINT subscription_events_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: track_downloads track_downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.track_downloads
    ADD CONSTRAINT track_downloads_pkey PRIMARY KEY (id);


--
-- Name: tracks tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: generation_runs_comfy_prompt_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX generation_runs_comfy_prompt_unique ON public.generation_runs USING btree (comfy_prompt_id) WHERE (comfy_prompt_id IS NOT NULL);


--
-- Name: genre_entitlements_unique_per_subscription; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX genre_entitlements_unique_per_subscription ON public.genre_entitlements USING btree (subscription_id, genre_id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_audit_events_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_subject_type_and_subject_id ON public.audit_events USING btree (subject_type, subject_id);


--
-- Name: index_audit_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_user_id ON public.audit_events USING btree (user_id);


--
-- Name: index_audit_events_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_user_id_and_created_at ON public.audit_events USING btree (user_id, created_at);


--
-- Name: index_consent_records_on_subject_token_and_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_consent_records_on_subject_token_and_kind ON public.consent_records USING btree (subject_token, kind);


--
-- Name: index_data_requests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_requests_on_user_id ON public.data_requests USING btree (user_id);


--
-- Name: index_generation_batches_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_generation_batches_on_created_by_id ON public.generation_batches USING btree (created_by_id);


--
-- Name: index_generation_batches_on_genre_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_generation_batches_on_genre_id ON public.generation_batches USING btree (genre_id);


--
-- Name: index_generation_batches_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_generation_batches_on_status ON public.generation_batches USING btree (status);


--
-- Name: index_generation_runs_on_generation_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_generation_runs_on_generation_batch_id ON public.generation_runs USING btree (generation_batch_id);


--
-- Name: index_generation_runs_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_generation_runs_on_status ON public.generation_runs USING btree (status);


--
-- Name: index_generation_runs_on_track_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_generation_runs_on_track_id ON public.generation_runs USING btree (track_id);


--
-- Name: index_genre_entitlements_on_genre_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genre_entitlements_on_genre_id ON public.genre_entitlements USING btree (genre_id);


--
-- Name: index_genre_entitlements_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genre_entitlements_on_subscription_id ON public.genre_entitlements USING btree (subscription_id);


--
-- Name: index_genres_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genres_on_position ON public.genres USING btree ("position");


--
-- Name: index_genres_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_genres_on_slug ON public.genres USING btree (slug);


--
-- Name: index_newsletter_subscribers_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_newsletter_subscribers_on_email ON public.newsletter_subscribers USING btree (email);


--
-- Name: index_orders_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orders_on_number ON public.orders USING btree (number);


--
-- Name: index_orders_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_plan_id ON public.orders USING btree (plan_id);


--
-- Name: index_orders_on_public_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orders_on_public_token ON public.orders USING btree (public_token);


--
-- Name: index_orders_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_status ON public.orders USING btree (status);


--
-- Name: index_orders_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_user_id ON public.orders USING btree (user_id);


--
-- Name: index_pages_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pages_on_slug ON public.pages USING btree (slug);


--
-- Name: index_plans_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plans_on_position ON public.plans USING btree ("position");


--
-- Name: index_plans_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_plans_on_slug ON public.plans USING btree (slug);


--
-- Name: index_posts_on_published_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_published_at ON public.posts USING btree (published_at);


--
-- Name: index_posts_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_posts_on_slug ON public.posts USING btree (slug);


--
-- Name: index_redirects_on_from_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_redirects_on_from_path ON public.redirects USING btree (from_path);


--
-- Name: index_subscription_events_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_events_on_subscription_id ON public.subscription_events USING btree (subscription_id);


--
-- Name: index_subscription_events_on_subscription_id_and_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_events_on_subscription_id_and_occurred_at ON public.subscription_events USING btree (subscription_id, occurred_at);


--
-- Name: index_subscriptions_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_plan_id ON public.subscriptions USING btree (plan_id);


--
-- Name: index_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_user_id ON public.subscriptions USING btree (user_id);


--
-- Name: index_track_downloads_on_track_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_track_downloads_on_track_id ON public.track_downloads USING btree (track_id);


--
-- Name: index_track_downloads_on_track_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_track_downloads_on_track_id_and_created_at ON public.track_downloads USING btree (track_id, created_at);


--
-- Name: index_track_downloads_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_track_downloads_on_user_id ON public.track_downloads USING btree (user_id);


--
-- Name: index_track_downloads_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_track_downloads_on_user_id_and_created_at ON public.track_downloads USING btree (user_id, created_at);


--
-- Name: index_tracks_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracks_on_discarded_at ON public.tracks USING btree (discarded_at);


--
-- Name: index_tracks_on_genre_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracks_on_genre_id ON public.tracks USING btree (genre_id);


--
-- Name: index_tracks_on_genre_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracks_on_genre_id_and_status ON public.tracks USING btree (genre_id, status);


--
-- Name: index_tracks_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracks_on_position ON public.tracks USING btree ("position");


--
-- Name: index_tracks_on_published_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracks_on_published_at ON public.tracks USING btree (published_at);


--
-- Name: index_tracks_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tracks_on_slug ON public.tracks USING btree (slug);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: orders_provider_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX orders_provider_id_unique ON public.orders USING btree (provider, provider_order_id) WHERE (provider_order_id IS NOT NULL);


--
-- Name: subscriptions_one_live_per_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX subscriptions_one_live_per_user ON public.subscriptions USING btree (user_id) WHERE ((status)::text = ANY ((ARRAY['incomplete'::character varying, 'active'::character varying, 'past_due'::character varying])::text[]));


--
-- Name: subscriptions_provider_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX subscriptions_provider_id_unique ON public.subscriptions USING btree (provider, provider_subscription_id) WHERE (provider_subscription_id IS NOT NULL);


--
-- Name: consent_records consent_records_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER consent_records_append_only BEFORE DELETE OR UPDATE ON public.consent_records FOR EACH ROW EXECUTE FUNCTION public.prevent_modification();


--
-- Name: subscription_events subscription_events_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER subscription_events_append_only BEFORE DELETE OR UPDATE ON public.subscription_events FOR EACH ROW EXECUTE FUNCTION public.prevent_modification();


--
-- Name: track_downloads track_downloads_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER track_downloads_append_only BEFORE DELETE OR UPDATE ON public.track_downloads FOR EACH ROW EXECUTE FUNCTION public.prevent_modification();


--
-- Name: genre_entitlements fk_rails_23cc1a8d23; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genre_entitlements
    ADD CONSTRAINT fk_rails_23cc1a8d23 FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: generation_batches fk_rails_39c0116987; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_batches
    ADD CONSTRAINT fk_rails_39c0116987 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: data_requests fk_rails_45595fed14; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_requests
    ADD CONSTRAINT fk_rails_45595fed14 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: generation_batches fk_rails_46f4c8f3b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_batches
    ADD CONSTRAINT fk_rails_46f4c8f3b1 FOREIGN KEY (genre_id) REFERENCES public.genres(id);


--
-- Name: subscriptions fk_rails_63d3df128b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_63d3df128b FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- Name: generation_runs fk_rails_849c271bde; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_runs
    ADD CONSTRAINT fk_rails_849c271bde FOREIGN KEY (generation_batch_id) REFERENCES public.generation_batches(id);


--
-- Name: subscription_events fk_rails_93168323a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_events
    ADD CONSTRAINT fk_rails_93168323a0 FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: subscriptions fk_rails_933bdff476; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_933bdff476 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: generation_runs fk_rails_ab8e595fee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_runs
    ADD CONSTRAINT fk_rails_ab8e595fee FOREIGN KEY (track_id) REFERENCES public.tracks(id);


--
-- Name: genre_entitlements fk_rails_c2d9871af8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genre_entitlements
    ADD CONSTRAINT fk_rails_c2d9871af8 FOREIGN KEY (genre_id) REFERENCES public.genres(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: track_downloads fk_rails_c4bc6b2db4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.track_downloads
    ADD CONSTRAINT fk_rails_c4bc6b2db4 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: audit_events fk_rails_d27dff91d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT fk_rails_d27dff91d1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: tracks fk_rails_e21e3bd01e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT fk_rails_e21e3bd01e FOREIGN KEY (genre_id) REFERENCES public.genres(id);


--
-- Name: orders fk_rails_f868b47f6a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_f868b47f6a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: track_downloads fk_rails_f8fd9eef5f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.track_downloads
    ADD CONSTRAINT fk_rails_f8fd9eef5f FOREIGN KEY (track_id) REFERENCES public.tracks(id);


--
-- Name: orders fk_rails_fc5c7eaeee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_fc5c7eaeee FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260918180012'),
('20260918180011'),
('20260918180010'),
('20260918180009'),
('20260918180008'),
('20260918180007'),
('20260918180006'),
('20260918180005'),
('20260918180004'),
('20260918180003'),
('20260918180002'),
('20260918180001'),
('20260918180000'),
('20260918174605'),
('20260918174552');

