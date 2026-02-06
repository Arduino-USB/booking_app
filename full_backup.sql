--
-- PostgreSQL database dump
--

\restrict MYFJm27PVnr5pd4AwkUwQHEjffjJ2Xb7I2VzqZKXth7O1vpECn7XBgy3aeKH9hp

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
        RAISE EXCEPTION 'Person is not available for this time slot';
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
        RAISE EXCEPTION 'Booking overlaps with an existing booking for this person';
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
    server_id integer NOT NULL
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
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: booking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.booking (id, date_created, created_by, date_resv_start, date_resv_end, server_id) FROM stdin;
\.


--
-- Data for Name: booking_open; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.booking_open (id, user_id, start_time, end_time) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, pass, username, type) FROM stdin;
44	Admin	\\x24326224313224623430617032524c7a6556793569446a7a657850614f6536613979344a553974504b5441385943733456464e774d7063586e614565	admin	admin
\.


--
-- Name: booking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.booking_id_seq', 0, false);


--
-- Name: booking_open_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.booking_open_id_seq', 0, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 44, true);


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
-- Name: booking_open booking_open_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_open
    ADD CONSTRAINT booking_open_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: TABLE booking; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.booking TO db_user;


--
-- Name: TABLE booking_open; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.booking_open TO db_user;


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

\unrestrict MYFJm27PVnr5pd4AwkUwQHEjffjJ2Xb7I2VzqZKXth7O1vpECn7XBgy3aeKH9hp

