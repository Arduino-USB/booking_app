--
-- PostgreSQL database dump
--

\restrict itJqnH2zIkITN8kTNtrRB9bNGnQlKbeKiRIHrfzRJAEtBiQVbqcOCIuoKYDLUWs

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

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
-- Name: check_booking_length(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_booking_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    required_length INTERVAL;
BEGIN
    -- Get required length from menu
    SELECT length
    INTO required_length
    FROM menu
    WHERE id = NEW.menu_id;

    -- Safety check (shouldn’t happen if FK exists)
    IF required_length IS NULL THEN
        RAISE EXCEPTION 'Invalid menu_id %', NEW.menu_id;
    END IF;

    -- Compare durations directly (interval vs interval)
    IF (NEW.date_resv_end - NEW.date_resv_start) < required_length THEN
        RAISE EXCEPTION
        'Booking duration is shorter than required menu length (%)',
        required_length;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_booking_length() OWNER TO postgres;

--
-- Name: check_booking_open(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_booking_open() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- sanity check
    IF NEW.date_resv_start >= NEW.date_resv_end THEN
        RAISE EXCEPTION 'Booking start time must be before end time';
    END IF;

    -- check booking is within an open slot of the SERVER
    IF NOT EXISTS (
        SELECT 1
        FROM booking_open bo
        WHERE bo.user_id = NEW.server_id
          AND NEW.date_resv_start < bo.end_time
          AND NEW.date_resv_end   > bo.start_time
    ) THEN
        RAISE EXCEPTION 'Server is not available for this time slot';
    END IF;

    -- check overlap with existing bookings for the SAME SERVER
    IF EXISTS (
        SELECT 1
        FROM booking b
        WHERE b.server_id = NEW.server_id
          -- exclude self on UPDATE
          AND (TG_OP = 'INSERT' OR b.id <> NEW.id)
          AND NEW.date_resv_start < b.date_resv_end
          AND NEW.date_resv_end   > b.date_resv_start
    ) THEN
        RAISE EXCEPTION 'Booking overlaps with an existing booking for this server';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_booking_open() OWNER TO postgres;

--
-- Name: check_user_type(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_user_type() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM users
        WHERE id = NEW.user_id
          AND type = 'user'
    ) THEN
        RAISE EXCEPTION 'Only users of type other than "user" can have booking_open slots';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_user_type() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: booking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.booking (
    id integer NOT NULL,
    date_created timestamp without time zone DEFAULT now(),
    created_by integer,
    date_resv_start timestamp without time zone,
    date_resv_end timestamp without time zone,
    server_id integer NOT NULL,
    key_id integer,
    key text,
    menu_id integer
);


ALTER TABLE public.booking OWNER TO postgres;

--
-- Name: booking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.booking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.booking_id_seq OWNER TO postgres;

--
-- Name: booking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.booking_id_seq OWNED BY public.booking.id;


--
-- Name: booking_open; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.booking_open (
    id integer NOT NULL,
    user_id integer,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    CONSTRAINT booking_open_check CHECK ((end_time > start_time))
);


ALTER TABLE public.booking_open OWNER TO postgres;

--
-- Name: booking_open_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.booking_open_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.booking_open_id_seq OWNER TO postgres;

--
-- Name: booking_open_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.booking_open_id_seq OWNED BY public.booking_open.id;


--
-- Name: keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.keys (
    id integer NOT NULL,
    key text
);


ALTER TABLE public.keys OWNER TO postgres;

--
-- Name: keys_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.keys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.keys_id_seq OWNER TO postgres;

--
-- Name: keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.keys_id_seq OWNED BY public.keys.id;


--
-- Name: menu; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menu (
    id integer NOT NULL,
    name text,
    length interval
);


ALTER TABLE public.menu OWNER TO postgres;

--
-- Name: menu_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menu_id_seq OWNER TO postgres;

--
-- Name: menu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_id_seq OWNED BY public.menu.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name text NOT NULL,
    pass text NOT NULL,
    username text NOT NULL,
    type text
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: booking id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking ALTER COLUMN id SET DEFAULT nextval('public.booking_id_seq'::regclass);


--
-- Name: booking_open id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_open ALTER COLUMN id SET DEFAULT nextval('public.booking_open_id_seq'::regclass);


--
-- Name: keys id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keys ALTER COLUMN id SET DEFAULT nextval('public.keys_id_seq'::regclass);


--
-- Name: menu id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu ALTER COLUMN id SET DEFAULT nextval('public.menu_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: booking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.booking (id, date_created, created_by, date_resv_start, date_resv_end, server_id, key_id, key, menu_id) FROM stdin;
9	2026-02-10 13:29:51.225377	\N	2026-02-11 00:00:00	2026-02-27 00:00:00	49	\N	f4ec5f0a-c3ff-4025-bf30-046ba9e8b9f5	\N
\.


--
-- Data for Name: booking_open; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.booking_open (id, user_id, start_time, end_time) FROM stdin;
3	49	2026-02-05 17:00:00	2026-02-05 18:00:00
4	49	2026-02-05 17:00:00	2026-02-05 18:00:00
5	49	2026-02-10 00:00:00	2026-02-28 00:00:00
\.


--
-- Data for Name: keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.keys (id, key) FROM stdin;
1	6ddc7df5-97ed-4e0f-8500-9355da601e22
2	b19d2e5b-888e-4270-9bd8-e6bad7ddb19f
3	b3e1baf6-9871-4d7c-85ce-7048929a715e
4	32fb208e-87a1-4b92-bfc3-32f663ef01eb
5	f4ec5f0a-c3ff-4025-bf30-046ba9e8b9f5
\.


--
-- Data for Name: menu; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.menu (id, name, length) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, pass, username, type) FROM stdin;
44	Admin	\\x24326224313224623430617032524c7a6556793569446a7a657850614f6536613979344a553974504b5441385943733456464e774d7063586e614565	admin	admin
47	test	\\x24326224313224363074566e633036764e4a3049712f43476a47692f4f683753313434544a645477585a4831505432455056563442495030687a3757	test	user
49	serv	\\x2432622431322464546132614d6c467673464541323743315979556e2e6a6e716e5a755168633238357a48545137367735654333454f484f43436e79	serv	serv
\.


--
-- Name: booking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.booking_id_seq', 9, true);


--
-- Name: booking_open_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.booking_open_id_seq', 5, true);


--
-- Name: keys_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.keys_id_seq', 5, true);


--
-- Name: menu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.menu_id_seq', 0, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 49, true);


--
-- Name: booking booking_key_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_key_id_key UNIQUE (key_id);


--
-- Name: booking booking_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_key_key UNIQUE (key);


--
-- Name: booking_open booking_open_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_open
    ADD CONSTRAINT booking_open_pkey PRIMARY KEY (id);


--
-- Name: booking booking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_pkey PRIMARY KEY (id);


--
-- Name: keys keys_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_key_key UNIQUE (key);


--
-- Name: keys keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_pkey PRIMARY KEY (id);


--
-- Name: menu menu_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu
    ADD CONSTRAINT menu_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_unique UNIQUE (username);


--
-- Name: booking booking_length_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_length_trigger BEFORE INSERT ON public.booking FOR EACH ROW EXECUTE FUNCTION public.check_booking_length();


--
-- Name: booking booking_open_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_open_check BEFORE INSERT ON public.booking FOR EACH ROW EXECUTE FUNCTION public.check_booking_open();


--
-- Name: booking_open booking_open_user_type; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_open_user_type BEFORE INSERT OR UPDATE ON public.booking_open FOR EACH ROW EXECUTE FUNCTION public.check_user_type();


--
-- Name: booking booking_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: booking booking_key_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_key_id_fkey FOREIGN KEY (key_id) REFERENCES public.keys(id);


--
-- Name: booking booking_menu_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_menu_id_fkey FOREIGN KEY (menu_id) REFERENCES public.menu(id);


--
-- Name: booking_open booking_open_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_open
    ADD CONSTRAINT booking_open_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: TABLE booking; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.booking TO db_user;


--
-- Name: SEQUENCE booking_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.booking_id_seq TO db_user;


--
-- Name: TABLE booking_open; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.booking_open TO db_user;


--
-- Name: SEQUENCE booking_open_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.booking_open_id_seq TO db_user;


--
-- Name: TABLE keys; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.keys TO db_user;


--
-- Name: SEQUENCE keys_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.keys_id_seq TO db_user;


--
-- Name: TABLE menu; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.menu TO db_user;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.users TO db_user;


--
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.users_id_seq TO db_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO db_user;


--
-- PostgreSQL database dump complete
--

\unrestrict itJqnH2zIkITN8kTNtrRB9bNGnQlKbeKiRIHrfzRJAEtBiQVbqcOCIuoKYDLUWs

