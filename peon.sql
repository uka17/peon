--
-- PostgreSQL database dump
--

-- Dumped from database version 11.3 (Debian 11.3-1.pgdg90+1)
-- Dumped by pg_dump version 11.4 (Ubuntu 11.4-1.pgdg18.04+1)

-- Started on 2019-07-17 21:44:59 MSK

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 208 (class 1255 OID 16385)
-- Name: fnConnection_Count(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Count"() RETURNS bigint
    LANGUAGE sql
    AS $$SELECT COUNT(1) as count FROM public."tblConnection"$$;


--
-- TOC entry 209 (class 1255 OID 16386)
-- Name: fnConnection_Delete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Delete"(connection_id integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblConnection" c SET 
		"isDeleted" = true
	WHERE "id" = connection_id;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 210 (class 1255 OID 16387)
-- Name: fnConnection_Insert(json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Insert"(connection json, created_by text) RETURNS integer
    LANGUAGE sql
    AS $$
    INSERT INTO public."tblConnection"("connection", "modifiedBy", "createdBy") VALUES (connection, created_by, created_by) RETURNING "id"
$$;


--
-- TOC entry 211 (class 1255 OID 16388)
-- Name: fnConnection_Select(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Select"(connection_id integer) RETURNS json
    LANGUAGE sql
    AS $$
	SELECT row_to_json("tblConnection") 
	FROM "tblConnection" 
	WHERE "id" = connection_id AND NULLIF("isDeleted", false) IS NULL;
$$;


--
-- TOC entry 212 (class 1255 OID 16389)
-- Name: fnConnection_SelectAll(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_SelectAll"() RETURNS json
    LANGUAGE sql
    AS $$
	SELECT array_to_json(array_agg(row_to_json(t))) FROM (SELECT * FROM "tblConnection" WHERE NULLIF("isDeleted", false) IS NULL) t;	
$$;


--
-- TOC entry 213 (class 1255 OID 16390)
-- Name: fnConnection_Update(integer, json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Update"(connection_id integer, connection_body json, modified_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblConnection" j SET 
		"connection" = connection_body,
		"modifiedBy" = modified_by,
		"modifiedOn" = NOW()
	WHERE "id" = connection_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 214 (class 1255 OID 16391)
-- Name: fnGetJobStatusId(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnGetJobStatusId"(status text) RETURNS integer
    LANGUAGE sql
    AS $$SELECT Id FROM public."refJobStatus" r where r.status = status$$;


--
-- TOC entry 215 (class 1255 OID 16392)
-- Name: fnJobHistory_Insert(json, uuid, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJobHistory_Insert"(message json, session_id uuid, job_id integer, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblJobHistory"("message", "session", "jobId", "createdBy") VALUES (message, session_id, job_id, createdBy) RETURNING "id" $$;


--
-- TOC entry 216 (class 1255 OID 16393)
-- Name: fnJob_Count(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Count"() RETURNS bigint
    LANGUAGE sql
    AS $$SELECT COUNT(1) as count FROM public."tblJob"$$;


--
-- TOC entry 217 (class 1255 OID 16394)
-- Name: fnJob_Delete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Delete"(job_id integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"isDeleted" = true
	WHERE "id" = job_id;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 218 (class 1255 OID 16395)
-- Name: fnJob_Insert(json, timestamp without time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Insert"(job json, next_run timestamp without time zone, created_by text) RETURNS integer
    LANGUAGE sql
    AS $$
    INSERT INTO public."tblJob"("job", "nextRun", "modifiedBy", "createdBy") VALUES (job, next_run, created_by, created_by) RETURNING "id"
$$;


--
-- TOC entry 219 (class 1255 OID 16396)
-- Name: fnJob_Select(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Select"(job_id integer) RETURNS json
    LANGUAGE sql
    AS $$
	SELECT row_to_json("tblJob") 
	FROM "tblJob" 
	WHERE "id" = job_id AND NULLIF("isDeleted", false) IS NULL;
$$;


--
-- TOC entry 220 (class 1255 OID 16397)
-- Name: fnJob_SelectAll(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_SelectAll"() RETURNS json
    LANGUAGE sql
    AS $$
	SELECT array_to_json(array_agg(row_to_json(t))) FROM (SELECT * FROM "tblJob" WHERE NULLIF("isDeleted", false) IS NULL) t;	
$$;


--
-- TOC entry 221 (class 1255 OID 16398)
-- Name: fnJob_ToRun(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_ToRun"(tolerance integer) RETURNS json
    LANGUAGE sql
    AS $$
    SELECT 
		array_to_json(array_agg(row_to_json(t))) 
	FROM (SELECT 
		  	* 
		  FROM "tblJob" j
		  WHERE j."nextRun" BETWEEN now() - (tolerance || ' minutes')::interval AND now() + (tolerance || ' minutes')::interval
		  and j."statusId" = 1
		 ) t;
$$;


--
-- TOC entry 222 (class 1255 OID 16399)
-- Name: fnJob_Update(integer, json, timestamp without time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Update"(job_id integer, job_body json, next_run timestamp without time zone, modified_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"job" = job_body,
		"nextRun" = next_run,
		"modifiedBy" = modified_by,
		"modifiedOn" = NOW()
	WHERE "id" = job_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 235 (class 1255 OID 16400)
-- Name: fnJob_UpdateNextRun(integer, timestamp without time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_UpdateNextRun"(job_id integer, next_run timestamp without time zone, modified_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"nextRun" = next_run,
		"modifiedBy" = modified_by,
		"modifiedOn" = NOW()
	WHERE "id" = job_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 236 (class 1255 OID 16401)
-- Name: fnJob_UpdateStatus(integer, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_UpdateStatus"(job_id integer, status_id integer, modified_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"statusId" = status_id,
		"modifiedBy" = modified_by,
		"modifiedOn" = NOW()
	WHERE "id" = job_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 237 (class 1255 OID 16402)
-- Name: fnLog_Insert(integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnLog_Insert"(type integer, message text, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblLog"("type", "message", "createdBy") VALUES (type, message, createdBy) RETURNING "id" $$;


--
-- TOC entry 238 (class 1255 OID 16403)
-- Name: fnRunHistory_Insert(text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnRunHistory_Insert"(message text, session_id uuid, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblRunHistory"("message", "session", "createdBy") VALUES (message, session_id, createdBy) RETURNING "id" $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 196 (class 1259 OID 16404)
-- Name: refJobStatus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."refJobStatus" (
    id integer NOT NULL,
    status text NOT NULL,
    "modifiedOn" timestamp without time zone DEFAULT now() NOT NULL,
    "modifiedBy" text NOT NULL,
    "createdOn" timestamp without time zone DEFAULT now() NOT NULL,
    "createdBy" text NOT NULL,
    "isDeleted" boolean
);


--
-- TOC entry 197 (class 1259 OID 16412)
-- Name: refJobStatus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."refJobStatus_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2963 (class 0 OID 0)
-- Dependencies: 197
-- Name: refJobStatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."refJobStatus_id_seq" OWNED BY public."refJobStatus".id;


--
-- TOC entry 198 (class 1259 OID 16414)
-- Name: tblConnection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."tblConnection" (
    id integer NOT NULL,
    connection json,
    "modifiedOn" timestamp without time zone DEFAULT now() NOT NULL,
    "modifiedBy" text NOT NULL,
    "createdOn" timestamp without time zone DEFAULT now() NOT NULL,
    "createdBy" text NOT NULL,
    "isDeleted" boolean
);


--
-- TOC entry 199 (class 1259 OID 16422)
-- Name: tblConnection_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."tblConnection_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2964 (class 0 OID 0)
-- Dependencies: 199
-- Name: tblConnection_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblConnection_id_seq" OWNED BY public."tblConnection".id;


--
-- TOC entry 200 (class 1259 OID 16424)
-- Name: tblJob; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."tblJob" (
    id integer NOT NULL,
    job json,
    "modifiedOn" timestamp without time zone DEFAULT now() NOT NULL,
    "modifiedBy" text NOT NULL,
    "createdOn" timestamp without time zone DEFAULT now() NOT NULL,
    "createdBy" text NOT NULL,
    "isDeleted" boolean,
    "statusId" integer DEFAULT public."fnGetJobStatusId"('idle'::text) NOT NULL,
    "nextRun" timestamp without time zone
);


--
-- TOC entry 201 (class 1259 OID 16433)
-- Name: tblJobHistory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."tblJobHistory" (
    id integer NOT NULL,
    message json NOT NULL,
    "createdOn" timestamp without time zone DEFAULT now() NOT NULL,
    "createdBy" text NOT NULL,
    "jobId" integer NOT NULL,
    session uuid
);


--
-- TOC entry 202 (class 1259 OID 16440)
-- Name: tblJobHistory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."tblJobHistory_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2965 (class 0 OID 0)
-- Dependencies: 202
-- Name: tblJobHistory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblJobHistory_id_seq" OWNED BY public."tblJobHistory".id;


--
-- TOC entry 203 (class 1259 OID 16442)
-- Name: tblJob_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."tblJob_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2966 (class 0 OID 0)
-- Dependencies: 203
-- Name: tblJob_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblJob_Id_seq" OWNED BY public."tblJob".id;


--
-- TOC entry 204 (class 1259 OID 16444)
-- Name: tblLog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."tblLog" (
    id integer NOT NULL,
    type integer NOT NULL,
    message text NOT NULL,
    "createdOn" timestamp without time zone DEFAULT now() NOT NULL,
    "createdBy" text NOT NULL
);


--
-- TOC entry 205 (class 1259 OID 16451)
-- Name: tblLog_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."tblLog_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2967 (class 0 OID 0)
-- Dependencies: 205
-- Name: tblLog_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblLog_Id_seq" OWNED BY public."tblLog".id;


--
-- TOC entry 206 (class 1259 OID 16453)
-- Name: tblRunHistory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."tblRunHistory" (
    id integer NOT NULL,
    message text NOT NULL,
    "createdOn" timestamp without time zone DEFAULT now() NOT NULL,
    "createdBy" text NOT NULL,
    session uuid
);


--
-- TOC entry 207 (class 1259 OID 16460)
-- Name: tblRunHistory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."tblRunHistory_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2968 (class 0 OID 0)
-- Dependencies: 207
-- Name: tblRunHistory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblRunHistory_id_seq" OWNED BY public."tblRunHistory".id;


--
-- TOC entry 2797 (class 2604 OID 16462)
-- Name: refJobStatus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."refJobStatus" ALTER COLUMN id SET DEFAULT nextval('public."refJobStatus_id_seq"'::regclass);


--
-- TOC entry 2800 (class 2604 OID 16463)
-- Name: tblConnection id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblConnection" ALTER COLUMN id SET DEFAULT nextval('public."tblConnection_id_seq"'::regclass);


--
-- TOC entry 2804 (class 2604 OID 16464)
-- Name: tblJob id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob" ALTER COLUMN id SET DEFAULT nextval('public."tblJob_Id_seq"'::regclass);


--
-- TOC entry 2806 (class 2604 OID 16465)
-- Name: tblJobHistory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory" ALTER COLUMN id SET DEFAULT nextval('public."tblJobHistory_id_seq"'::regclass);


--
-- TOC entry 2808 (class 2604 OID 16466)
-- Name: tblLog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblLog" ALTER COLUMN id SET DEFAULT nextval('public."tblLog_Id_seq"'::regclass);


--
-- TOC entry 2810 (class 2604 OID 16467)
-- Name: tblRunHistory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblRunHistory" ALTER COLUMN id SET DEFAULT nextval('public."tblRunHistory_id_seq"'::regclass);


--
-- TOC entry 2946 (class 0 OID 16404)
-- Dependencies: 196
-- Data for Name: refJobStatus; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."refJobStatus" (id, status, "modifiedOn", "modifiedBy", "createdOn", "createdBy", "isDeleted") FROM stdin;
1	idle	2019-05-18 00:36:30.585459	system	2019-05-18 00:36:30.585459	system	\N
2	execution	2019-05-18 00:36:30.585459	system	2019-05-18 00:36:30.585459	system	\N
\.


--
-- TOC entry 2948 (class 0 OID 16414)
-- Dependencies: 198
-- Data for Name: tblConnection; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblConnection" (id, connection, "modifiedOn", "modifiedBy", "createdOn", "createdBy", "isDeleted") FROM stdin;
15	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:35:26.047464	test	2019-05-14 20:35:26.047464	test	\N
26	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:40:10.264855	test	2019-05-14 20:40:10.244508	test	t
27	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:40:56.644127	test	2019-05-14 20:40:56.644127	test	\N
16	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:35:26.087101	test	2019-05-14 20:35:26.066177	test	\N
17	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:36:56.394983	test	2019-05-14 20:36:56.394983	test	\N
18	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:36:56.435748	test	2019-05-14 20:36:56.413929	test	t
19	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:38:00.629711	test	2019-05-14 20:38:00.629711	test	\N
37	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:44:34.283819	test	2019-05-14 20:44:34.283819	test	\N
1	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:10:00.54222	test	2019-05-14 20:10:00.54222	test	\N
2	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:10:00.560868	test	2019-05-14 20:10:00.560868	test	\N
3	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:25:28.228034	test	2019-05-14 20:25:28.228034	test	\N
4	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:25:28.264817	test	2019-05-14 20:25:28.24603	test	\N
5	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:26:29.331232	test	2019-05-14 20:26:29.331232	test	\N
6	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:26:29.367646	test	2019-05-14 20:26:29.349094	test	\N
7	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:28:15.603653	test	2019-05-14 20:28:15.603653	test	\N
8	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:28:15.642718	test	2019-05-14 20:28:15.621855	test	\N
9	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:29:08.061614	test	2019-05-14 20:29:08.061614	test	\N
10	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:29:08.110813	test	2019-05-14 20:29:08.080412	test	\N
11	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:29:32.75545	test	2019-05-14 20:29:32.75545	test	\N
12	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:29:32.794025	test	2019-05-14 20:29:32.773975	test	\N
13	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:29:53.331377	test	2019-05-14 20:29:53.331377	test	\N
14	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:29:53.371349	test	2019-05-14 20:29:53.350643	test	\N
20	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:38:00.668897	test	2019-05-14 20:38:00.648036	test	t
21	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:38:18.866671	test	2019-05-14 20:38:18.866671	test	\N
28	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:40:56.689948	test	2019-05-14 20:40:56.668538	test	t
22	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:38:18.905129	test	2019-05-14 20:38:18.884943	test	t
23	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:38:48.720328	test	2019-05-14 20:38:48.720328	test	\N
29	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:41:09.809688	test	2019-05-14 20:41:09.809688	test	\N
24	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:38:48.752521	test	2019-05-14 20:38:48.739029	test	t
25	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:40:10.225908	test	2019-05-14 20:40:10.225908	test	\N
32	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:41:30.855955	test	2019-05-14 20:41:30.831038	test	t
33	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:41:37.994328	test	2019-05-14 20:41:37.994328	test	\N
30	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:41:09.851778	test	2019-05-14 20:41:09.838087	test	t
31	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:41:30.810494	test	2019-05-14 20:41:30.810494	test	\N
36	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:42:32.506402	test	2019-05-14 20:42:32.484058	test	t
34	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:41:38.023062	test	2019-05-14 20:41:38.013915	test	t
35	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:42:32.464291	test	2019-05-14 20:42:32.464291	test	\N
38	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:44:34.314578	test	2019-05-14 20:44:34.30262	test	t
39	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:45:19.45065	test	2019-05-14 20:45:19.45065	test	\N
74	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 20:44:09.314569	test	2019-05-16 20:44:09.314569	test	t
40	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 20:45:19.484129	test	2019-05-14 20:45:19.469868	test	t
41	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:03:52.777247	test	2019-05-14 21:03:52.777247	test	\N
60	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:11:44.344415	test	2019-05-14 21:11:44.329621	test	t
42	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:03:52.808176	test	2019-05-14 21:03:52.796319	test	t
43	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:04:19.812656	test	2019-05-14 21:04:19.812656	test	\N
61	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:13:25.068551	test	2019-05-14 21:13:25.068551	test	\N
44	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:04:19.846094	test	2019-05-14 21:04:19.831791	test	t
45	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:06:11.737741	test	2019-05-14 21:06:11.737741	test	\N
46	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:06:11.768754	test	2019-05-14 21:06:11.756462	test	t
47	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:06:41.370167	test	2019-05-14 21:06:41.370167	test	\N
70	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 19:04:39.746476	test	2019-05-16 19:04:39.731961	test	t
48	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:06:41.401239	test	2019-05-14 21:06:41.388868	test	t
49	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:06:48.807059	test	2019-05-14 21:06:48.807059	test	\N
62	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:13:25.103725	test	2019-05-14 21:13:25.08741	test	t
50	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:06:48.855715	test	2019-05-14 21:06:48.837988	test	t
51	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:09:58.185868	test	2019-05-14 21:09:58.185868	test	\N
63	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-15 18:59:30.67113	test	2019-05-15 18:59:30.67113	test	\N
52	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:09:58.219197	test	2019-05-14 21:09:58.205017	test	t
53	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:10:28.956744	test	2019-05-14 21:10:28.956744	test	\N
54	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:10:28.989045	test	2019-05-14 21:10:28.976336	test	t
55	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:10:53.580157	test	2019-05-14 21:10:53.580157	test	\N
71	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 19:06:57.437777	test	2019-05-16 19:06:57.437777	test	\N
56	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:10:53.612485	test	2019-05-14 21:10:53.599797	test	t
57	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:11:30.207864	test	2019-05-14 21:11:30.207864	test	\N
64	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-15 18:59:30.704795	test	2019-05-15 18:59:30.685654	test	t
58	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:11:30.241587	test	2019-05-14 21:11:30.22671	test	t
59	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-14 21:11:44.310015	test	2019-05-14 21:11:44.310015	test	\N
65	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 19:04:00.896816	test	2019-05-16 19:04:00.896816	test	\N
66	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 19:04:00.882593	test	2019-05-16 19:04:00.882593	test	\N
67	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 19:04:09.369048	test	2019-05-16 19:04:09.369048	test	\N
68	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 19:04:09.387145	test	2019-05-16 19:04:09.387145	test	t
69	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 19:04:39.713779	test	2019-05-16 19:04:39.713779	test	\N
75	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 20:44:34.678535	test	2019-05-16 20:44:34.678535	test	\N
72	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 19:06:57.471144	test	2019-05-16 19:06:57.456463	test	t
73	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 20:44:09.29652	test	2019-05-16 20:44:09.29652	test	\N
79	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 19:06:55.787033	test	2019-05-25 19:06:55.755351	test	\N
76	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 20:44:34.711271	test	2019-05-16 20:44:34.696173	test	t
77	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 20:45:17.399386	test	2019-05-16 20:45:17.399386	test	\N
78	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-16 20:45:17.433982	test	2019-05-16 20:45:17.418331	test	t
80	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 19:06:55.760131	test	2019-05-25 19:06:55.760131	test	t
81	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 19:07:14.818044	test	2019-05-25 19:07:14.818044	test	\N
82	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 19:07:14.850569	test	2019-05-25 19:07:14.836431	test	t
83	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 19:10:53.749766	test	2019-05-25 19:10:53.749766	test	\N
100	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:37:05.083664	test	2019-05-25 20:37:05.069172	test	t
84	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 19:10:53.791586	test	2019-05-25 19:10:53.769288	test	t
85	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 19:11:25.598774	test	2019-05-25 19:11:25.598774	test	\N
101	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:37:23.501927	test	2019-05-25 20:37:23.501927	test	\N
86	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 19:11:25.631981	test	2019-05-25 19:11:25.617665	test	t
87	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 19:13:04.536242	test	2019-05-25 19:13:04.536242	test	\N
88	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 19:13:04.569971	test	2019-05-25 19:13:04.554959	test	t
89	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:01:07.238262	test	2019-05-25 20:01:07.238262	test	\N
110	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:40:40.813042	test	2019-05-25 20:40:40.795754	test	t
90	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:01:07.272631	test	2019-05-25 20:01:07.256072	test	t
91	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:01:13.358074	test	2019-05-25 20:01:13.358074	test	\N
102	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:37:23.535874	test	2019-05-25 20:37:23.520798	test	t
92	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:01:13.391228	test	2019-05-25 20:01:13.376376	test	t
93	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:04:47.724754	test	2019-05-25 20:04:47.724754	test	\N
103	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:38:01.577096	test	2019-05-25 20:38:01.577096	test	\N
94	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:04:47.759968	test	2019-05-25 20:04:47.743334	test	t
95	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:33:44.151872	test	2019-05-25 20:33:44.151872	test	\N
96	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:33:44.185651	test	2019-05-25 20:33:44.17083	test	t
97	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:36:46.543372	test	2019-05-25 20:36:46.543372	test	\N
111	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:41:19.736354	test	2019-05-25 20:41:19.736354	test	\N
98	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:36:46.576797	test	2019-05-25 20:36:46.56224	test	t
99	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:37:05.05037	test	2019-05-25 20:37:05.05037	test	\N
104	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:38:01.609972	test	2019-05-25 20:38:01.595673	test	t
105	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:39:24.822551	test	2019-05-25 20:39:24.822551	test	\N
106	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:39:24.841241	test	2019-05-25 20:39:24.841241	test	t
107	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:40:03.402848	test	2019-05-25 20:40:03.402848	test	\N
108	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:40:03.438221	test	2019-05-25 20:40:03.421389	test	t
109	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:40:40.776406	test	2019-05-25 20:40:40.776406	test	\N
114	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:41:36.187399	test	2019-05-25 20:41:36.170669	test	t
112	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:41:19.772682	test	2019-05-25 20:41:19.754725	test	t
113	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-25 20:41:36.151762	test	2019-05-25 20:41:36.151762	test	\N
115	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 08:11:27.33143	test	2019-05-26 08:11:27.33143	test	\N
116	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 08:11:27.373159	test	2019-05-26 08:11:27.350682	test	t
117	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 08:29:10.354003	test	2019-05-26 08:29:10.354003	test	\N
118	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 08:29:10.389025	test	2019-05-26 08:29:10.372738	test	t
119	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:25:12.370159	test	2019-05-26 10:25:12.370159	test	\N
120	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:25:12.410639	test	2019-05-26 10:25:12.39094	test	t
121	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:26:13.744708	test	2019-05-26 10:26:13.744708	test	\N
140	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:40:51.819259	test	2019-05-26 10:40:51.803945	test	t
122	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:26:13.778483	test	2019-05-26 10:26:13.764077	test	t
123	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:30:30.886261	test	2019-05-26 10:30:30.886261	test	\N
141	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:41:46.393253	test	2019-05-26 10:41:46.393253	test	\N
124	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:30:30.92633	test	2019-05-26 10:30:30.905685	test	t
125	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:33:58.236724	test	2019-05-26 10:33:58.236724	test	\N
126	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:33:58.274263	test	2019-05-26 10:33:58.258616	test	t
127	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:34:36.798306	test	2019-05-26 10:34:36.798306	test	\N
150	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:45:03.719148	test	2019-05-26 10:45:03.701318	test	t
128	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:34:36.831002	test	2019-05-26 10:34:36.816804	test	t
129	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:38:15.414847	test	2019-05-26 10:38:15.414847	test	\N
142	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:41:46.429591	test	2019-05-26 10:41:46.414031	test	t
130	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:38:15.452032	test	2019-05-26 10:38:15.436999	test	t
131	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:38:29.46638	test	2019-05-26 10:38:29.46638	test	\N
143	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:42:05.536188	test	2019-05-26 10:42:05.536188	test	\N
132	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:38:29.501783	test	2019-05-26 10:38:29.485344	test	t
133	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:39:12.231819	test	2019-05-26 10:39:12.231819	test	\N
134	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:39:12.267392	test	2019-05-26 10:39:12.250975	test	t
135	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:40:01.978787	test	2019-05-26 10:40:01.978787	test	\N
136	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:40:02.018427	test	2019-05-26 10:40:01.999431	test	t
137	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:40:29.397258	test	2019-05-26 10:40:29.397258	test	\N
144	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:42:05.57533	test	2019-05-26 10:42:05.552395	test	t
138	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:40:29.435057	test	2019-05-26 10:40:29.419062	test	t
139	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:40:51.784568	test	2019-05-26 10:40:51.784568	test	\N
145	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:42:37.187263	test	2019-05-26 10:42:37.187263	test	\N
152	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:47:24.067117	test	2019-05-26 10:47:24.067117	test	\N
146	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:42:37.2198	test	2019-05-26 10:42:37.205576	test	t
147	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:44:43.967888	test	2019-05-26 10:44:43.967888	test	\N
154	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:48:01.397872	test	2019-05-26 10:48:01.381872	test	t
148	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:44:44.005238	test	2019-05-26 10:44:43.986789	test	t
149	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:45:03.682593	test	2019-05-26 10:45:03.682593	test	\N
151	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:47:24.088253	test	2019-05-26 10:47:24.048197	test	t
153	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:48:01.36113	test	2019-05-26 10:48:01.36113	test	\N
155	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:48:23.785025	test	2019-05-26 10:48:23.785025	test	\N
156	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:48:23.821373	test	2019-05-26 10:48:23.804061	test	t
157	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:49:08.331729	test	2019-05-26 10:49:08.331729	test	\N
158	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:49:08.366958	test	2019-05-26 10:49:08.350705	test	t
159	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:50:41.255812	test	2019-05-26 10:50:41.255812	test	\N
194	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 19:47:13.927205	test	2019-05-31 19:47:13.927205	test	t
160	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 10:50:41.289678	test	2019-05-26 10:50:41.273902	test	t
161	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 11:31:23.142076	test	2019-05-26 11:31:23.142076	test	\N
180	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 21:53:59.52866	test	2019-05-26 21:53:59.514299	test	t
162	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 11:31:23.178093	test	2019-05-26 11:31:23.162075	test	t
163	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 11:31:30.808688	test	2019-05-26 11:31:30.808688	test	\N
181	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 22:24:31.020747	test	2019-05-26 22:24:31.020747	test	\N
164	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 11:31:30.843617	test	2019-05-26 11:31:30.827196	test	t
165	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 12:39:46.378092	test	2019-05-26 12:39:46.378092	test	\N
166	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 12:39:46.411041	test	2019-05-26 12:39:46.396829	test	t
167	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 13:27:52.920419	test	2019-05-26 13:27:52.920419	test	\N
190	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-28 20:13:44.897456	test	2019-05-28 20:13:44.881589	test	t
168	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 13:27:52.951797	test	2019-05-26 13:27:52.938997	test	t
169	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 13:28:58.507213	test	2019-05-26 13:28:58.507213	test	\N
182	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 22:24:31.058036	test	2019-05-26 22:24:31.040542	test	t
170	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 13:28:58.540918	test	2019-05-26 13:28:58.526423	test	t
171	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 14:09:57.570666	test	2019-05-26 14:09:57.570666	test	\N
183	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-27 20:21:06.894435	test	2019-05-27 20:21:06.894435	test	\N
172	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 14:09:57.603651	test	2019-05-26 14:09:57.589409	test	t
173	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 14:10:35.487399	test	2019-05-26 14:10:35.487399	test	\N
174	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 14:10:35.521826	test	2019-05-26 14:10:35.506758	test	t
175	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 14:23:47.14554	test	2019-05-26 14:23:47.14554	test	\N
191	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-28 20:14:28.960229	test	2019-05-28 20:14:28.960229	test	\N
176	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 14:23:47.17742	test	2019-05-26 14:23:47.164375	test	t
177	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 21:53:32.153228	test	2019-05-26 21:53:32.153228	test	\N
178	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 21:53:32.173369	test	2019-05-26 21:53:32.173369	test	t
179	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-26 21:53:59.493806	test	2019-05-26 21:53:59.493806	test	\N
184	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-27 20:21:06.929044	test	2019-05-27 20:21:06.913997	test	t
185	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-27 20:21:40.144039	test	2019-05-27 20:21:40.144039	test	\N
186	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-27 20:21:40.18216	test	2019-05-27 20:21:40.163581	test	t
187	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-27 20:35:47.594308	test	2019-05-27 20:35:47.594308	test	\N
195	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 19:49:08.870969	test	2019-05-31 19:49:08.870969	test	\N
188	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-27 20:35:47.628275	test	2019-05-27 20:35:47.614015	test	t
189	{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-28 20:13:44.864284	test	2019-05-28 20:13:44.864284	test	\N
192	{"name":"test_connection","host":"test","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-28 20:14:28.990275	test	2019-05-28 20:14:28.973311	test	t
193	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 19:47:13.910241	test	2019-05-31 19:47:13.910241	test	\N
196	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 19:49:08.906656	test	2019-05-31 19:49:08.889782	test	t
197	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 19:49:29.627393	test	2019-05-31 19:49:29.627393	test	\N
198	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 19:49:29.660499	test	2019-05-31 19:49:29.645935	test	t
199	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 19:55:57.453338	test	2019-05-31 19:55:57.453338	test	\N
200	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 19:55:57.489491	test	2019-05-31 19:55:57.470836	test	t
201	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 19:58:59.402675	test	2019-05-31 19:58:59.402675	test	\N
202	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 19:58:59.436329	test	2019-05-31 19:58:59.422206	test	t
203	{"name":"test_connection","host":"172.17.0.2","port":5432,"database":"peon","enabled":true,"login":"postgres","password":"255320","type":"postgresql"}	2019-05-31 20:03:08.848119	test	2019-05-31 20:03:08.848119	test	\N
204	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 20:11:26.129521	test	2019-05-31 20:11:26.129521	test	\N
205	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-05-31 20:11:26.161289	test	2019-05-31 20:11:26.148624	test	t
206	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-06-06 08:48:10.784928	test	2019-06-06 08:48:10.784928	test	\N
207	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-06-06 08:48:10.823947	test	2019-06-06 08:48:10.800022	test	\N
208	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-06-06 08:49:05.573753	test	2019-06-06 08:49:05.573753	test	\N
209	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-06-06 08:49:05.609317	test	2019-06-06 08:49:05.591181	test	t
210	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-06-06 19:10:47.486011	test	2019-06-06 19:10:47.486011	test	\N
211	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-06-06 19:10:47.519107	test	2019-06-06 19:10:47.502061	test	t
212	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:00:10.069213	test	2019-07-03 18:00:10.069213	test	\N
235	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:11:30.834726	test	2019-07-03 19:11:30.819678	test	t
213	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:00:10.108003	test	2019-07-03 18:00:10.092255	test	t
214	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:36:30.662153	test	2019-07-03 18:36:30.662153	test	\N
229	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:08:26.311973	test	2019-07-03 19:08:26.29684	test	t
215	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:36:30.701878	test	2019-07-03 18:36:30.685029	test	t
216	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:39:56.639344	test	2019-07-03 18:39:56.639344	test	\N
230	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:08:41.337877	test	2019-07-03 19:08:41.337877	test	\N
217	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:39:56.677998	test	2019-07-03 18:39:56.662199	test	t
218	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:41:59.729047	test	2019-07-03 18:41:59.729047	test	\N
219	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:41:59.768964	test	2019-07-03 18:41:59.753387	test	t
220	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:49:43.674029	test	2019-07-03 18:49:43.674029	test	\N
236	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:12:49.219778	test	2019-07-03 19:12:49.219778	test	\N
221	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:49:43.710963	test	2019-07-03 18:49:43.695961	test	t
222	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:50:50.764814	test	2019-07-03 18:50:50.764814	test	\N
231	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:08:41.375417	test	2019-07-03 19:08:41.360169	test	t
223	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:50:50.801921	test	2019-07-03 18:50:50.786925	test	t
224	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:52:33.103016	test	2019-07-03 18:52:33.103016	test	\N
232	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:10:54.159861	test	2019-07-03 19:10:54.159861	test	\N
225	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 18:52:33.142287	test	2019-07-03 18:52:33.126313	test	t
226	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:07:45.04024	test	2019-07-03 19:07:45.04024	test	\N
227	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:07:45.077933	test	2019-07-03 19:07:45.06248	test	t
228	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:08:26.273191	test	2019-07-03 19:08:26.273191	test	\N
233	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:10:54.197847	test	2019-07-03 19:10:54.182395	test	t
234	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:11:30.796667	test	2019-07-03 19:11:30.796667	test	\N
239	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:32:34.012151	test	2019-07-03 19:32:33.996846	test	t
237	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:12:49.257934	test	2019-07-03 19:12:49.242422	test	t
238	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:32:33.975172	test	2019-07-03 19:32:33.975172	test	\N
240	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:32:47.722582	test	2019-07-03 19:32:47.722582	test	\N
241	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:32:47.758346	test	2019-07-03 19:32:47.744669	test	t
242	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:40:26.424636	test	2019-07-03 19:40:26.424636	test	\N
243	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:40:26.46194	test	2019-07-03 19:40:26.446534	test	t
244	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:40:26.710752	test	2019-07-03 19:40:26.710752	test	\N
265	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:54:21.592454	test	2019-07-03 19:54:21.592454	test	t
245	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:40:26.741681	test	2019-07-03 19:40:26.730279	test	t
246	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:41:12.84627	test	2019-07-03 19:41:12.84627	test	\N
247	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:41:12.872281	test	2019-07-03 19:41:12.872281	test	t
248	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:41:28.928595	test	2019-07-03 19:41:28.928595	test	\N
249	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:41:28.952953	test	2019-07-03 19:41:28.952953	test	t
250	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:42:19.024313	test	2019-07-03 19:42:19.024313	test	\N
251	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:42:19.049739	test	2019-07-03 19:42:19.049739	test	t
252	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:46:00.777118	test	2019-07-03 19:46:00.777118	test	\N
253	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:46:00.800669	test	2019-07-03 19:46:00.800669	test	t
254	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:46:54.643071	test	2019-07-03 19:46:54.643071	test	\N
255	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:46:54.667674	test	2019-07-03 19:46:54.667674	test	t
256	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:47:28.273603	test	2019-07-03 19:47:28.273603	test	\N
266	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:54:54.597405	test	2019-07-03 19:54:54.597405	test	\N
257	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:47:28.31862	test	2019-07-03 19:47:28.299769	test	t
258	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:52:03.949598	test	2019-07-03 19:52:03.949598	test	\N
259	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:52:03.993403	test	2019-07-03 19:52:03.974669	test	t
260	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:52:22.71172	test	2019-07-03 19:52:22.71172	test	\N
261	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:52:22.737525	test	2019-07-03 19:52:22.737525	test	t
262	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:52:46.504723	test	2019-07-03 19:52:46.504723	test	\N
267	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:54:54.621143	test	2019-07-03 19:54:54.621143	test	t
263	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:52:46.551256	test	2019-07-03 19:52:46.529433	test	t
264	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:54:21.568783	test	2019-07-03 19:54:21.568783	test	\N
268	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:55:00.379501	test	2019-07-03 19:55:00.379501	test	\N
269	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:55:00.40349	test	2019-07-03 19:55:00.40349	test	t
270	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:55:05.860919	test	2019-07-03 19:55:05.860919	test	\N
271	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:55:05.883355	test	2019-07-03 19:55:05.883355	test	t
272	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:55:11.687388	test	2019-07-03 19:55:11.687388	test	\N
273	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:55:11.710238	test	2019-07-03 19:55:11.710238	test	t
274	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:55:25.263696	test	2019-07-03 19:55:25.263696	test	\N
275	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:55:25.288767	test	2019-07-03 19:55:25.288767	test	t
276	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:58:13.732437	test	2019-07-03 19:58:13.732437	test	\N
277	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:58:13.755571	test	2019-07-03 19:58:13.755571	test	t
278	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:58:13.823021	test	2019-07-03 19:58:13.823021	test	\N
279	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:58:34.452947	test	2019-07-03 19:58:34.452947	test	\N
280	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:58:34.496888	test	2019-07-03 19:58:34.476353	test	\N
281	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:58:44.135231	test	2019-07-03 19:58:44.135231	test	\N
282	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 19:58:44.180506	test	2019-07-03 19:58:44.160469	test	\N
283	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:01:44.017153	test	2019-07-03 20:01:44.017153	test	\N
284	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:01:44.061427	test	2019-07-03 20:01:44.041443	test	\N
285	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:01:56.326685	test	2019-07-03 20:01:56.326685	test	\N
286	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:01:56.369526	test	2019-07-03 20:01:56.351272	test	\N
287	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:03:10.015777	test	2019-07-03 20:03:10.015777	test	\N
300	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:30:56.624988	test	2019-07-03 20:30:56.610756	test	\N
288	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:03:10.063418	test	2019-07-03 20:03:10.041469	test	t
289	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:06:57.779587	test	2019-07-03 20:06:57.779587	test	\N
291	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:06:57.827841	test	2019-07-03 20:06:57.81383	test	\N
290	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:06:57.802019	test	2019-07-03 20:06:57.802019	test	t
292	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:28:08.508017	test	2019-07-03 20:28:08.508017	test	\N
294	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:28:08.556325	test	2019-07-03 20:28:08.540414	test	\N
293	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:28:08.529945	test	2019-07-03 20:28:08.529945	test	t
295	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:28:54.42549	test	2019-07-03 20:28:54.42549	test	\N
297	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:28:54.473631	test	2019-07-03 20:28:54.459719	test	\N
296	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:28:54.447523	test	2019-07-03 20:28:54.447523	test	t
298	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:30:56.580013	test	2019-07-03 20:30:56.580013	test	\N
299	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:30:56.587367	test	2019-07-03 20:30:56.587367	test	t
301	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:32:19.208673	test	2019-07-03 20:32:19.208673	test	\N
303	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:32:19.252141	test	2019-07-03 20:32:19.238255	test	\N
302	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:32:19.216433	test	2019-07-03 20:32:19.216433	test	t
304	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:32:48.197267	test	2019-07-03 20:32:48.197267	test	\N
306	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:32:48.242931	test	2019-07-03 20:32:48.228141	test	\N
305	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:32:48.205637	test	2019-07-03 20:32:48.205637	test	t
307	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:37:39.966619	test	2019-07-03 20:37:39.966619	test	\N
309	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:37:40.017171	test	2019-07-03 20:37:40.000424	test	\N
308	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 20:37:39.976102	test	2019-07-03 20:37:39.976102	test	t
310	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 21:03:42.524642	test	2019-07-03 21:03:42.524642	test	\N
312	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 21:03:42.57253	test	2019-07-03 21:03:42.556938	test	\N
311	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-03 21:03:42.532082	test	2019-07-03 21:03:42.532082	test	t
313	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:30:20.876258	test	2019-07-04 20:30:20.876258	test	\N
314	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:30:20.883795	test	2019-07-04 20:30:20.883795	test	t
315	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:30:20.920713	test	2019-07-04 20:30:20.905816	test	\N
316	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:31:22.495096	test	2019-07-04 20:31:22.495096	test	\N
318	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:31:22.538795	test	2019-07-04 20:31:22.524498	test	\N
317	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:31:22.502422	test	2019-07-04 20:31:22.502422	test	t
319	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:36:13.304495	test	2019-07-04 20:36:13.304495	test	\N
321	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:36:13.348013	test	2019-07-04 20:36:13.333787	test	\N
320	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:36:13.312179	test	2019-07-04 20:36:13.312179	test	t
322	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:36:35.676888	test	2019-07-04 20:36:35.676888	test	\N
324	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:36:35.721864	test	2019-07-04 20:36:35.706899	test	\N
323	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:36:35.6845	test	2019-07-04 20:36:35.6845	test	t
325	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:42:33.940791	test	2019-07-04 20:42:33.940791	test	\N
327	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:42:33.987295	test	2019-07-04 20:42:33.970502	test	\N
326	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:42:33.948263	test	2019-07-04 20:42:33.948263	test	t
328	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:43:50.484598	test	2019-07-04 20:43:50.484598	test	\N
330	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:43:50.528379	test	2019-07-04 20:43:50.514164	test	\N
329	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:43:50.491988	test	2019-07-04 20:43:50.491988	test	t
331	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:45:26.108842	test	2019-07-04 20:45:26.108842	test	\N
333	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:45:26.155457	test	2019-07-04 20:45:26.14032	test	\N
332	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:45:26.11682	test	2019-07-04 20:45:26.11682	test	t
334	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:47:03.973832	test	2019-07-04 20:47:03.973832	test	\N
336	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:47:04.020258	test	2019-07-04 20:47:04.003689	test	\N
335	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:47:03.981631	test	2019-07-04 20:47:03.981631	test	t
337	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:48:24.695443	test	2019-07-04 20:48:24.695443	test	\N
339	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:48:24.741173	test	2019-07-04 20:48:24.726406	test	\N
338	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:48:24.704147	test	2019-07-04 20:48:24.704147	test	t
340	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:49:32.584318	test	2019-07-04 20:49:32.584318	test	\N
342	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:49:32.627457	test	2019-07-04 20:49:32.612904	test	\N
341	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-04 20:49:32.592026	test	2019-07-04 20:49:32.592026	test	t
343	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:27:50.314506	test	2019-07-05 20:27:50.314506	test	\N
345	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:27:50.358138	test	2019-07-05 20:27:50.34398	test	\N
344	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:27:50.322181	test	2019-07-05 20:27:50.322181	test	t
346	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:28:59.266133	test	2019-07-05 20:28:59.266133	test	\N
348	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:28:59.3134	test	2019-07-05 20:28:59.298846	test	\N
347	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:28:59.274123	test	2019-07-05 20:28:59.274123	test	t
349	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:29:36.426298	test	2019-07-05 20:29:36.426298	test	\N
350	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:29:36.434579	test	2019-07-05 20:29:36.434579	test	t
351	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:29:36.47083	test	2019-07-05 20:29:36.455791	test	\N
352	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:30:21.547729	test	2019-07-05 20:30:21.547729	test	\N
354	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:30:21.590155	test	2019-07-05 20:30:21.575416	test	\N
353	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:30:21.554697	test	2019-07-05 20:30:21.554697	test	t
355	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:30:30.962059	test	2019-07-05 20:30:30.962059	test	\N
357	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:30:31.006008	test	2019-07-05 20:30:30.990369	test	\N
356	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:30:30.969586	test	2019-07-05 20:30:30.969586	test	t
358	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:31:15.190885	test	2019-07-05 20:31:15.190885	test	\N
360	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:31:15.233342	test	2019-07-05 20:31:15.219318	test	\N
359	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:31:15.199482	test	2019-07-05 20:31:15.199482	test	t
361	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:31:56.561442	test	2019-07-05 20:31:56.561442	test	\N
363	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:31:56.605205	test	2019-07-05 20:31:56.589361	test	\N
362	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:31:56.56908	test	2019-07-05 20:31:56.56908	test	t
364	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:33:01.507818	test	2019-07-05 20:33:01.507818	test	\N
366	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:33:01.550777	test	2019-07-05 20:33:01.53655	test	\N
365	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:33:01.514898	test	2019-07-05 20:33:01.514898	test	t
367	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:34:23.452115	test	2019-07-05 20:34:23.452115	test	\N
369	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:34:23.494849	test	2019-07-05 20:34:23.480241	test	\N
368	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:34:23.45961	test	2019-07-05 20:34:23.45961	test	t
370	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:35:16.29506	test	2019-07-05 20:35:16.29506	test	\N
372	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:35:16.339291	test	2019-07-05 20:35:16.324084	test	\N
371	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:35:16.302458	test	2019-07-05 20:35:16.302458	test	t
373	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:36:34.314517	test	2019-07-05 20:36:34.314517	test	\N
375	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:36:34.356673	test	2019-07-05 20:36:34.342835	test	\N
374	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:36:34.321462	test	2019-07-05 20:36:34.321462	test	t
376	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:37:39.828852	test	2019-07-05 20:37:39.828852	test	\N
378	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:37:39.871193	test	2019-07-05 20:37:39.85734	test	\N
377	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:37:39.837215	test	2019-07-05 20:37:39.837215	test	t
379	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:43:44.022166	test	2019-07-05 20:43:44.022166	test	\N
381	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:43:44.066455	test	2019-07-05 20:43:44.051702	test	\N
380	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:43:44.031087	test	2019-07-05 20:43:44.031087	test	t
382	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:43:53.814188	test	2019-07-05 20:43:53.814188	test	\N
384	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:43:53.858556	test	2019-07-05 20:43:53.843436	test	\N
383	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:43:53.822175	test	2019-07-05 20:43:53.822175	test	t
385	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:47:07.529833	test	2019-07-05 20:47:07.529833	test	\N
386	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:47:07.537715	test	2019-07-05 20:47:07.537715	test	t
387	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:47:07.575295	test	2019-07-05 20:47:07.560027	test	\N
388	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:47:53.583195	test	2019-07-05 20:47:53.583195	test	\N
390	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:47:53.625495	test	2019-07-05 20:47:53.611327	test	\N
389	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:47:53.590348	test	2019-07-05 20:47:53.590348	test	t
391	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:48:42.098139	test	2019-07-05 20:48:42.098139	test	\N
393	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:48:42.146726	test	2019-07-05 20:48:42.130756	test	\N
392	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:48:42.106628	test	2019-07-05 20:48:42.106628	test	t
394	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:49:09.930005	test	2019-07-05 20:49:09.930005	test	\N
396	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:49:09.974725	test	2019-07-05 20:49:09.959689	test	\N
395	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:49:09.938445	test	2019-07-05 20:49:09.938445	test	t
397	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:50:15.539978	test	2019-07-05 20:50:15.539978	test	\N
399	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:50:15.582435	test	2019-07-05 20:50:15.568663	test	\N
398	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:50:15.547513	test	2019-07-05 20:50:15.547513	test	t
400	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:51:18.669126	test	2019-07-05 20:51:18.669126	test	\N
402	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:51:18.714697	test	2019-07-05 20:51:18.69813	test	\N
401	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:51:18.676856	test	2019-07-05 20:51:18.676856	test	t
403	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:51:31.208086	test	2019-07-05 20:51:31.208086	test	\N
405	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:51:31.254369	test	2019-07-05 20:51:31.238866	test	\N
404	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-05 20:51:31.215902	test	2019-07-05 20:51:31.215902	test	t
406	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-07 21:03:41.873835	test	2019-07-07 21:03:41.873835	test	\N
407	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-07 21:03:41.912655	test	2019-07-07 21:03:41.895743	test	\N
408	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-07 21:03:41.911136	test	2019-07-07 21:03:41.911136	test	t
409	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-08 19:37:31.540698	testRobot	2019-07-08 19:37:31.540698	testRobot	\N
416	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 18:44:11.498116	testRobot	2019-07-17 18:44:11.475125	testRobot	t
410	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-08 19:37:31.594237	testRobot	2019-07-08 19:37:31.563998	testRobot	t
411	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 18:35:01.463701	testRobot	2019-07-17 18:35:01.463701	testRobot	\N
414	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 18:39:41.392771	testRobot	2019-07-17 18:39:41.366609	testRobot	t
412	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 18:35:01.515216	testRobot	2019-07-17 18:35:01.490272	testRobot	t
413	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 18:39:41.343177	testRobot	2019-07-17 18:39:41.343177	testRobot	\N
415	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 18:44:11.450993	testRobot	2019-07-17 18:44:11.450993	testRobot	\N
\.


--
-- TOC entry 2950 (class 0 OID 16424)
-- Dependencies: 200
-- Data for Name: tblJob; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblJob" (id, job, "modifiedOn", "modifiedBy", "createdOn", "createdBy", "isDeleted", "statusId", "nextRun") FROM stdin;
315	{"name":"test job","description":"test job description","enabled":true,"steps":[{"name":"step1","enabled":true,"connection":1,"database":"database","command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"database":"database","command":"select \\"fnLog_Insert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:12:11"}}]}	2019-05-30 19:57:04.969003	uat	2019-05-30 19:40:32.869116	test	\N	1	2019-05-31 11:12:11
316	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 19:47:13.997415	test	2019-05-31 19:47:13.997415	test	\N	1	2019-06-03 11:11:11
317	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 19:47:14.088451	test	2019-05-31 19:47:14.047296	test	t	1	2019-06-03 11:11:11
287	{"name":"job","description":"job description","enabled":true,"steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:12:11"}}]}	2019-05-29 20:14:20.102342	system	2019-05-26 12:55:20.042693	test	\N	1	2019-05-31 11:12:11
318	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 19:49:08.955514	test	2019-05-31 19:49:08.955514	test	\N	1	2019-06-03 11:11:11
319	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 19:49:09.038855	test	2019-05-31 19:49:08.995673	test	t	1	2019-06-03 11:11:11
320	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 19:49:29.711821	test	2019-05-31 19:49:29.711821	test	\N	1	2019-06-03 11:11:11
321	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 19:49:29.795108	test	2019-05-31 19:49:29.752032	test	t	1	2019-06-03 11:11:11
322	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 19:55:57.541788	test	2019-05-31 19:55:57.541788	test	\N	1	2019-06-03 11:11:11
323	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 19:55:57.625077	test	2019-05-31 19:55:57.58273	test	t	1	2019-06-03 11:11:11
324	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 19:58:59.491297	test	2019-05-31 19:58:59.491297	test	\N	1	2019-06-03 11:11:11
325	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 19:58:59.576338	test	2019-05-31 19:58:59.533761	test	t	1	2019-06-03 11:11:11
326	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 20:11:26.216297	test	2019-05-31 20:11:26.216297	test	\N	1	2019-06-03 11:11:11
327	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-05-31 20:11:26.301575	test	2019-05-31 20:11:26.25672	test	t	1	2019-06-03 11:11:11
331	{"name":"test job","description":"test job description","enabled":true,"steps":[{"name":"step1","enabled":true,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":10,"intervalType":"minute"}}}]}	2019-06-06 19:10:00.347041	system	2019-06-06 09:59:42.963864	test	\N	1	2019-06-06 19:20:00
332	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-06-06 19:10:47.566498	test	2019-06-06 19:10:47.566498	test	\N	1	2019-06-07 11:11:11
329	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-06-06 08:49:05.660059	test	2019-06-06 08:49:05.660059	test	\N	1	2019-06-07 11:11:11
330	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-06-06 08:49:05.769041	test	2019-06-06 08:49:05.702692	test	t	1	2019-06-07 11:11:11
328	{"name":"test job","description":"test job description","enabled":true,"steps":[{"name":"step1","enabled":true,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":203,"command":"select \\"fnLog1_Insert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:12:11"}}]}	2019-06-06 09:50:53.674484	systems	2019-05-31 20:44:51.535334	test	\N	1	2019-06-07 11:12:11
333	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-06-06 19:10:47.647705	test	2019-06-06 19:10:47.606968	test	t	1	2019-06-07 11:11:11
334	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:00:10.160637	test	2019-07-03 18:00:10.160637	test	\N	1	2019-07-05 11:11:11
335	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:00:10.243367	test	2019-07-03 18:00:10.205626	test	t	1	2019-07-05 11:11:11
336	{"name":"test job","description":"test job description","enabled":true,"steps":[{"name":"step1","enabled":true,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T18:30:00.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":10,"intervalType":"minute"}}}]}	2019-07-03 18:30:00.455719	system	2019-07-03 18:28:38.232292	test	\N	1	2019-07-03 18:40:00
337	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:36:30.758556	test	2019-07-03 18:36:30.758556	test	\N	1	2019-07-05 11:11:11
338	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:36:30.839267	test	2019-07-03 18:36:30.802786	test	t	1	2019-07-05 11:11:11
339	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:39:56.727321	test	2019-07-03 18:39:56.727321	test	\N	1	2019-07-05 11:11:11
340	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:39:56.808514	test	2019-07-03 18:39:56.770836	test	t	1	2019-07-05 11:11:11
341	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:41:59.819393	test	2019-07-03 18:41:59.819393	test	\N	1	2019-07-05 11:11:11
342	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:41:59.902342	test	2019-07-03 18:41:59.863924	test	t	1	2019-07-05 11:11:11
343	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:49:43.763261	test	2019-07-03 18:49:43.763261	test	\N	1	2019-07-05 11:11:11
344	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:49:43.844657	test	2019-07-03 18:49:43.803537	test	t	1	2019-07-05 11:11:11
345	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:50:50.853072	test	2019-07-03 18:50:50.853072	test	\N	1	2019-07-05 11:11:11
346	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:50:50.932219	test	2019-07-03 18:50:50.895778	test	t	1	2019-07-05 11:11:11
347	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:52:33.198265	test	2019-07-03 18:52:33.198265	test	\N	1	2019-07-05 11:11:11
348	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 18:52:33.297585	test	2019-07-03 18:52:33.247758	test	t	1	2019-07-05 11:11:11
349	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:07:45.128551	test	2019-07-03 19:07:45.128551	test	\N	1	2019-07-05 11:11:11
350	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:07:45.209323	test	2019-07-03 19:07:45.172629	test	t	1	2019-07-05 11:11:11
351	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:08:26.361815	test	2019-07-03 19:08:26.361815	test	\N	1	2019-07-05 11:11:11
352	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:08:26.44155	test	2019-07-03 19:08:26.4041	test	t	1	2019-07-05 11:11:11
353	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:08:41.426781	test	2019-07-03 19:08:41.426781	test	\N	1	2019-07-05 11:11:11
354	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:08:41.515755	test	2019-07-03 19:08:41.471671	test	t	1	2019-07-05 11:11:11
355	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:10:54.252444	test	2019-07-03 19:10:54.252444	test	\N	1	2019-07-05 11:11:11
356	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:10:54.342094	test	2019-07-03 19:10:54.302769	test	t	1	2019-07-05 11:11:11
357	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:11:30.884597	test	2019-07-03 19:11:30.884597	test	\N	1	2019-07-05 11:11:11
358	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:11:30.965314	test	2019-07-03 19:11:30.92678	test	t	1	2019-07-05 11:11:11
359	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:12:49.312715	test	2019-07-03 19:12:49.312715	test	\N	1	2019-07-05 11:11:11
360	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:12:49.433353	test	2019-07-03 19:12:49.39426	test	t	1	2019-07-05 11:11:11
361	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:32:34.065418	test	2019-07-03 19:32:34.065418	test	\N	1	2019-07-05 11:11:11
362	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:32:34.14552	test	2019-07-03 19:32:34.108756	test	t	1	2019-07-05 11:11:11
363	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:32:47.810354	test	2019-07-03 19:32:47.810354	test	\N	1	2019-07-05 11:11:11
364	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:32:47.888592	test	2019-07-03 19:32:47.852459	test	t	1	2019-07-05 11:11:11
365	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:40:26.514393	test	2019-07-03 19:40:26.514393	test	\N	1	2019-07-05 11:11:11
366	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:40:26.596858	test	2019-07-03 19:40:26.558354	test	t	1	2019-07-05 11:11:11
367	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:40:26.776158	test	2019-07-03 19:40:26.776158	test	\N	1	2019-07-05 11:11:11
368	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:40:26.85232	test	2019-07-03 19:40:26.814756	test	t	1	2019-07-05 11:11:11
369	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:41:12.945302	test	2019-07-03 19:41:12.945302	test	\N	1	2019-07-05 11:11:11
370	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:41:13.019386	test	2019-07-03 19:41:12.978024	test	t	1	2019-07-05 11:11:11
371	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:41:29.02531	test	2019-07-03 19:41:29.02531	test	\N	1	2019-07-05 11:11:11
372	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:41:29.100124	test	2019-07-03 19:41:29.058923	test	t	1	2019-07-05 11:11:11
373	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:42:19.121111	test	2019-07-03 19:42:19.121111	test	\N	1	2019-07-05 11:11:11
374	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:42:19.194592	test	2019-07-03 19:42:19.154043	test	t	1	2019-07-05 11:11:11
375	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:46:00.876299	test	2019-07-03 19:46:00.876299	test	\N	1	2019-07-05 11:11:11
376	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:46:00.952402	test	2019-07-03 19:46:00.911048	test	t	1	2019-07-05 11:11:11
377	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:46:54.73943	test	2019-07-03 19:46:54.73943	test	\N	1	2019-07-05 11:11:11
382	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:52:04.11439	test	2019-07-03 19:52:04.073136	test	t	1	2019-07-05 11:11:11
378	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:46:54.816852	test	2019-07-03 19:46:54.776005	test	t	1	2019-07-05 11:11:11
383	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:52:22.810497	test	2019-07-03 19:52:22.810497	test	\N	1	2019-07-05 11:11:11
380	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:47:28.440214	test	2019-07-03 19:47:28.399675	test	t	1	2019-07-05 11:11:11
379	{"name":"job","description":"job description","enabled":true,"steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:12:11"}}]}	2019-07-03 19:51:56.505248	test	2019-07-03 19:47:28.361486	test	\N	1	2019-07-05 11:12:11
381	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:52:04.03624	test	2019-07-03 19:52:04.03624	test	\N	1	2019-07-05 11:11:11
384	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:52:22.884881	test	2019-07-03 19:52:22.843933	test	t	1	2019-07-05 11:11:11
385	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:52:46.603187	test	2019-07-03 19:52:46.603187	test	\N	1	2019-07-05 11:11:11
386	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:52:46.676751	test	2019-07-03 19:52:46.629598	test	t	1	2019-07-05 11:11:11
387	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:54:21.666348	test	2019-07-03 19:54:21.666348	test	\N	1	2019-07-05 11:11:11
388	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:54:21.736317	test	2019-07-03 19:54:21.699865	test	t	1	2019-07-05 11:11:11
389	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:54:54.678317	test	2019-07-03 19:54:54.678317	test	\N	1	2019-07-05 11:11:11
390	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:54:54.716159	test	2019-07-03 19:54:54.716159	test	t	1	2019-07-05 11:11:11
391	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:55:00.462542	test	2019-07-03 19:55:00.462542	test	\N	1	2019-07-05 11:11:11
392	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:55:00.500187	test	2019-07-03 19:55:00.500187	test	t	1	2019-07-05 11:11:11
393	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:55:05.937947	test	2019-07-03 19:55:05.937947	test	\N	1	2019-07-05 11:11:11
394	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:55:05.975307	test	2019-07-03 19:55:05.975307	test	t	1	2019-07-05 11:11:11
395	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:55:11.769845	test	2019-07-03 19:55:11.769845	test	\N	1	2019-07-05 11:11:11
396	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:55:11.807094	test	2019-07-03 19:55:11.807094	test	t	1	2019-07-05 11:11:11
397	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:55:25.356881	test	2019-07-03 19:55:25.356881	test	\N	1	2019-07-05 11:11:11
398	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:55:25.427102	test	2019-07-03 19:55:25.389985	test	t	1	2019-07-05 11:11:11
399	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:58:13.821208	test	2019-07-03 19:58:13.821208	test	\N	1	2019-07-05 11:11:11
400	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:58:13.899626	test	2019-07-03 19:58:13.86427	test	t	1	2019-07-05 11:11:11
401	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:58:13.926033	test	2019-07-03 19:58:13.926033	test	\N	1	2019-07-05 11:11:11
402	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:58:34.533709	test	2019-07-03 19:58:34.533709	test	\N	1	2019-07-05 11:11:11
403	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:58:34.608989	test	2019-07-03 19:58:34.572132	test	\N	1	2019-07-05 11:11:11
404	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:58:44.220745	test	2019-07-03 19:58:44.220745	test	\N	1	2019-07-05 11:11:11
405	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 19:58:44.296983	test	2019-07-03 19:58:44.260555	test	\N	1	2019-07-05 11:11:11
406	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:01:44.098623	test	2019-07-03 20:01:44.098623	test	\N	1	2019-07-05 11:11:11
407	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:01:44.174922	test	2019-07-03 20:01:44.135517	test	\N	1	2019-07-05 11:11:11
408	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:01:56.425581	test	2019-07-03 20:01:56.425581	test	\N	1	2019-07-05 11:11:11
409	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:01:56.491007	test	2019-07-03 20:01:56.452789	test	\N	1	2019-07-05 11:11:11
410	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:03:10.118326	test	2019-07-03 20:03:10.118326	test	\N	1	2019-07-05 11:11:11
414	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:06:57.963322	test	2019-07-03 20:06:57.928515	test	\N	1	2019-07-05 11:11:11
411	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:03:10.184043	test	2019-07-03 20:03:10.147068	test	t	1	2019-07-05 11:11:11
412	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:06:57.871419	test	2019-07-03 20:06:57.871419	test	\N	1	2019-07-05 11:11:11
413	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:06:57.904453	test	2019-07-03 20:06:57.904453	test	t	1	2019-07-05 11:11:11
415	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:28:08.605423	test	2019-07-03 20:28:08.605423	test	\N	1	2019-07-05 11:11:11
416	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:28:08.640569	test	2019-07-03 20:28:08.640569	test	t	1	2019-07-05 11:11:11
417	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:28:08.701435	test	2019-07-03 20:28:08.665598	test	\N	1	2019-07-05 11:11:11
418	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:28:54.522112	test	2019-07-03 20:28:54.522112	test	\N	1	2019-07-05 11:11:11
420	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:28:54.615687	test	2019-07-03 20:28:54.580939	test	\N	1	2019-07-05 11:11:11
419	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:28:54.547162	test	2019-07-03 20:28:54.547162	test	t	1	2019-07-05 11:11:11
421	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:30:56.672375	test	2019-07-03 20:30:56.672375	test	\N	1	2019-07-05 11:11:11
423	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:30:56.768613	test	2019-07-03 20:30:56.731952	test	\N	1	2019-07-05 11:11:11
422	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:30:56.707	test	2019-07-03 20:30:56.707	test	t	1	2019-07-05 11:11:11
424	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:32:19.29786	test	2019-07-03 20:32:19.29786	test	\N	1	2019-07-05 11:11:11
431	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:37:40.098236	test	2019-07-03 20:37:40.098236	test	t	1	2019-07-05 11:11:11
425	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:32:19.333104	test	2019-07-03 20:32:19.333104	test	t	1	2019-07-05 11:11:11
426	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-17 18:44:11.353187	testBot	2019-07-03 20:32:19.356644	test	\N	1	2019-07-19 11:11:11
427	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:32:48.27597	test	2019-07-03 20:32:48.27597	test	\N	1	2019-07-05 11:11:11
429	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:32:48.368947	test	2019-07-03 20:32:48.332837	test	\N	1	2019-07-05 11:11:11
428	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:32:48.308511	test	2019-07-03 20:32:48.308511	test	t	1	2019-07-05 11:11:11
430	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:37:40.056847	test	2019-07-03 20:37:40.056847	test	\N	1	2019-07-05 11:11:11
432	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 20:37:40.167608	test	2019-07-03 20:37:40.124852	test	\N	1	2019-07-05 11:11:11
433	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 21:03:42.602582	test	2019-07-03 21:03:42.602582	test	\N	1	2019-07-05 11:11:11
435	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 21:03:42.700105	test	2019-07-03 21:03:42.665452	test	\N	1	2019-07-05 11:11:11
434	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-03 21:03:42.637826	test	2019-07-03 21:03:42.637826	test	t	1	2019-07-05 11:11:11
449	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:31:22.592476	test	2019-07-04 20:31:22.592476	test	t	1	2019-07-05 11:11:11
438	{"name":"test job","description":"test job description","enabled":true,"steps":[{"name":"step1","enabled":true,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T18:30:00.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":10,"intervalType":"minute"}}}],"nextRun":"2019-07-04T20:20:00.000Z"}	2019-07-04 20:20:00.574625	system	2019-07-04 20:14:45.094866	test	\N	1	2019-07-04 20:30:00
448	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:31:22.568914	test	2019-07-04 20:31:22.568914	test	\N	1	2019-07-05 11:11:11
450	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-04 20:31:22.664178	test	2019-07-04 20:31:22.629075	test	\N	1	2019-07-05 11:11:11
451	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:36:13.378166	test	2019-07-04 20:36:13.378166	test	\N	1	2019-07-05 11:11:11
453	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-04 20:36:13.480834	test	2019-07-04 20:36:13.43871	test	\N	1	2019-07-05 11:11:11
452	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:36:13.402212	test	2019-07-04 20:36:13.402212	test	t	1	2019-07-05 11:11:11
454	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:36:35.759168	test	2019-07-04 20:36:35.759168	test	\N	1	2019-07-05 11:11:11
456	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-04 20:36:35.852018	test	2019-07-04 20:36:35.818252	test	\N	1	2019-07-05 11:11:11
455	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:36:35.78384	test	2019-07-04 20:36:35.78384	test	t	1	2019-07-05 11:11:11
457	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:42:34.019247	test	2019-07-04 20:42:34.019247	test	\N	1	2019-07-05 11:11:11
459	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-04 20:42:34.118147	test	2019-07-04 20:42:34.080768	test	\N	1	2019-07-05 11:11:11
458	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:42:34.043499	test	2019-07-04 20:42:34.043499	test	t	1	2019-07-05 11:11:11
460	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:43:50.558621	test	2019-07-04 20:43:50.558621	test	\N	1	2019-07-05 11:11:11
462	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-04 20:43:50.655216	test	2019-07-04 20:43:50.619033	test	\N	1	2019-07-05 11:11:11
461	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:43:50.582505	test	2019-07-04 20:43:50.582505	test	t	1	2019-07-05 11:11:11
463	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:45:26.194949	test	2019-07-04 20:45:26.194949	test	\N	1	2019-07-05 11:11:11
465	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-04 20:45:26.291985	test	2019-07-04 20:45:26.255112	test	\N	1	2019-07-05 11:11:11
464	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:45:26.22014	test	2019-07-04 20:45:26.22014	test	t	1	2019-07-05 11:11:11
466	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:47:04.056006	test	2019-07-04 20:47:04.056006	test	\N	1	2019-07-05 11:11:11
467	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:47:04.094037	test	2019-07-04 20:47:04.094037	test	t	1	2019-07-05 11:11:11
468	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-04 20:47:04.160078	test	2019-07-04 20:47:04.120664	test	\N	1	2019-07-05 11:11:11
469	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:48:24.773636	test	2019-07-04 20:48:24.773636	test	\N	1	2019-07-05 11:11:11
471	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-04 20:48:24.875384	test	2019-07-04 20:48:24.836973	test	\N	1	2019-07-05 11:11:11
470	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:48:24.802199	test	2019-07-04 20:48:24.802199	test	t	1	2019-07-05 11:11:11
472	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:49:32.661782	test	2019-07-04 20:49:32.661782	test	\N	1	2019-07-05 11:11:11
474	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]}	2019-07-04 20:49:32.759345	test	2019-07-04 20:49:32.723608	test	\N	1	2019-07-05 11:11:11
473	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-05T11:11:11.000Z"}	2019-07-04 20:49:32.689041	test	2019-07-04 20:49:32.689041	test	t	1	2019-07-05 11:11:11
495	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:30:21.679957	test	2019-07-05 20:30:21.679957	test	\N	1	2019-07-08 11:11:11
494	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:30:21.645319	test	2019-07-05 20:30:21.645319	test	t	1	2019-07-08 11:11:11
501	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:31:15.360224	test	2019-07-05 20:31:15.323346	test	\N	1	2019-07-08 11:11:11
496	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:30:31.040326	test	2019-07-05 20:30:31.040326	test	\N	1	2019-07-08 11:11:11
490	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:29:36.501671	test	2019-07-05 20:29:36.501671	test	\N	1	2019-07-08 11:11:11
492	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:29:36.562316	test	2019-07-05 20:29:36.562316	test	\N	1	2019-07-08 11:11:11
491	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:29:36.524951	test	2019-07-05 20:29:36.524951	test	t	1	2019-07-08 11:11:11
498	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:30:31.103599	test	2019-07-05 20:30:31.103599	test	\N	1	2019-07-08 11:11:11
475	{"name":"test job","description":"test job description","enabled":true,"steps":[{"name":"step1","enabled":true,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T18:30:00.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":10,"intervalType":"minute"}}}],"nextRun":"2019-07-05T20:10:00.000Z"}	2019-07-05 20:30:00.703955	system	2019-07-05 20:08:30.28777	test	\N	1	2019-07-05 20:40:00
493	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:30:21.621221	test	2019-07-05 20:30:21.621221	test	\N	1	2019-07-08 11:11:11
497	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:30:31.067826	test	2019-07-05 20:30:31.067826	test	t	1	2019-07-08 11:11:11
499	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:31:15.264661	test	2019-07-05 20:31:15.264661	test	\N	1	2019-07-08 11:11:11
500	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:31:15.288203	test	2019-07-05 20:31:15.288203	test	t	1	2019-07-08 11:11:11
502	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:31:56.639315	test	2019-07-05 20:31:56.639315	test	\N	1	2019-07-08 11:11:11
504	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:31:56.733941	test	2019-07-05 20:31:56.696629	test	\N	1	2019-07-08 11:11:11
503	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:31:56.663101	test	2019-07-05 20:31:56.663101	test	t	1	2019-07-08 11:11:11
505	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:33:01.579636	test	2019-07-05 20:33:01.579636	test	\N	1	2019-07-08 11:11:11
507	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:33:01.675717	test	2019-07-05 20:33:01.640084	test	\N	1	2019-07-08 11:11:11
506	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:33:01.615284	test	2019-07-05 20:33:01.615284	test	t	1	2019-07-08 11:11:11
508	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:34:23.527494	test	2019-07-05 20:34:23.527494	test	\N	1	2019-07-08 11:11:11
509	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:34:23.550334	test	2019-07-05 20:34:23.550334	test	t	1	2019-07-08 11:11:11
510	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:34:23.623359	test	2019-07-05 20:34:23.585213	test	\N	1	2019-07-08 11:11:11
511	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:35:16.374183	test	2019-07-05 20:35:16.374183	test	\N	1	2019-07-08 11:11:11
513	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:35:16.472379	test	2019-07-05 20:35:16.433347	test	\N	1	2019-07-08 11:11:11
512	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:35:16.398781	test	2019-07-05 20:35:16.398781	test	t	1	2019-07-08 11:11:11
514	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:36:34.38809	test	2019-07-05 20:36:34.38809	test	\N	1	2019-07-08 11:11:11
516	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:36:34.482542	test	2019-07-05 20:36:34.446759	test	\N	1	2019-07-08 11:11:11
515	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:36:34.412135	test	2019-07-05 20:36:34.412135	test	t	1	2019-07-08 11:11:11
517	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:37:39.902464	test	2019-07-05 20:37:39.902464	test	\N	1	2019-07-08 11:11:11
519	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:37:39.996608	test	2019-07-05 20:37:39.960538	test	\N	1	2019-07-08 11:11:11
518	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:37:39.925627	test	2019-07-05 20:37:39.925627	test	t	1	2019-07-08 11:11:11
520	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:43:44.098931	test	2019-07-05 20:43:44.098931	test	\N	1	2019-07-08 11:11:11
522	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:43:44.192841	test	2019-07-05 20:43:44.157109	test	\N	1	2019-07-08 11:11:11
521	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:43:44.122971	test	2019-07-05 20:43:44.122971	test	t	1	2019-07-08 11:11:11
523	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:43:53.894359	test	2019-07-05 20:43:53.894359	test	\N	1	2019-07-08 11:11:11
525	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:43:54.00424	test	2019-07-05 20:43:53.961629	test	\N	1	2019-07-08 11:11:11
524	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:43:53.922754	test	2019-07-05 20:43:53.922754	test	t	1	2019-07-08 11:11:11
526	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:47:07.611576	test	2019-07-05 20:47:07.611576	test	\N	1	2019-07-08 11:11:11
528	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:47:07.70498	test	2019-07-05 20:47:07.668517	test	\N	1	2019-07-08 11:11:11
527	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:47:07.634391	test	2019-07-05 20:47:07.634391	test	t	1	2019-07-08 11:11:11
529	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:47:53.656837	test	2019-07-05 20:47:53.656837	test	\N	1	2019-07-08 11:11:11
531	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:47:53.753973	test	2019-07-05 20:47:53.718762	test	\N	1	2019-07-08 11:11:11
530	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:47:53.684852	test	2019-07-05 20:47:53.684852	test	t	1	2019-07-08 11:11:11
532	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:48:42.184665	test	2019-07-05 20:48:42.184665	test	\N	1	2019-07-08 11:11:11
534	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:48:42.289382	test	2019-07-05 20:48:42.247553	test	\N	1	2019-07-08 11:11:11
533	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:48:42.209199	test	2019-07-05 20:48:42.209199	test	t	1	2019-07-08 11:11:11
535	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:49:10.006541	test	2019-07-05 20:49:10.006541	test	\N	1	2019-07-08 11:11:11
537	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:49:10.116161	test	2019-07-05 20:49:10.076007	test	\N	1	2019-07-08 11:11:11
536	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:49:10.035824	test	2019-07-05 20:49:10.035824	test	t	1	2019-07-08 11:11:11
538	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:50:15.613564	test	2019-07-05 20:50:15.613564	test	\N	1	2019-07-08 11:11:11
540	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:50:15.704654	test	2019-07-05 20:50:15.669103	test	\N	1	2019-07-08 11:11:11
539	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:50:15.634599	test	2019-07-05 20:50:15.634599	test	t	1	2019-07-08 11:11:11
541	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:51:18.746312	test	2019-07-05 20:51:18.746312	test	\N	1	2019-07-08 11:11:11
542	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:51:18.774745	test	2019-07-05 20:51:18.774745	test	t	1	2019-07-08 11:11:11
543	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:51:18.846003	test	2019-07-05 20:51:18.809858	test	\N	1	2019-07-08 11:11:11
544	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:51:31.289013	test	2019-07-05 20:51:31.289013	test	\N	1	2019-07-08 11:11:11
546	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:51:31.391359	test	2019-07-05 20:51:31.351474	test	\N	1	2019-07-08 11:11:11
545	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-05 20:51:31.314604	test	2019-07-05 20:51:31.314604	test	t	1	2019-07-08 11:11:11
547	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-07 21:03:41.954959	test	2019-07-07 21:03:41.954959	test	\N	1	2019-07-08 11:11:11
548	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-07 21:03:42.046184	test	2019-07-07 21:03:41.989839	test	\N	1	2019-07-08 11:11:11
549	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-08T11:11:11.000Z"}	2019-07-07 21:03:42.020203	test	2019-07-07 21:03:42.020203	test	t	1	2019-07-08 11:11:11
550	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-10T11:11:11.000Z"}	2019-07-08 19:37:31.629674	testRobot	2019-07-08 19:37:31.629674	testRobot	\N	1	2019-07-10 11:11:11
552	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-19T11:11:11.000Z"}	2019-07-17 18:35:01.550153	testRobot	2019-07-17 18:35:01.550153	testRobot	\N	1	2019-07-19 11:11:11
551	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-10T11:11:11.000Z"}	2019-07-08 19:37:31.724358	testRobot	2019-07-08 19:37:31.675514	testRobot	t	1	2019-07-10 11:11:11
553	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-19T11:11:11.000Z"}	2019-07-17 18:35:01.63914	testRobot	2019-07-17 18:35:01.592556	testRobot	t	1	2019-07-19 11:11:11
554	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-19T11:11:11.000Z"}	2019-07-17 18:39:41.428934	testRobot	2019-07-17 18:39:41.428934	testRobot	\N	1	2019-07-19 11:11:11
555	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-19T11:11:11.000Z"}	2019-07-17 18:39:41.514425	testRobot	2019-07-17 18:39:41.468986	testRobot	t	1	2019-07-19 11:11:11
556	{"name":"job","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-19T11:11:11.000Z"}	2019-07-17 18:44:11.532834	testRobot	2019-07-17 18:44:11.532834	testRobot	\N	1	2019-07-19 11:11:11
557	{"name":"test","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}],"nextRun":"2019-07-19T11:11:11.000Z"}	2019-07-17 18:44:11.62153	testRobot	2019-07-17 18:44:11.57307	testRobot	t	1	2019-07-19 11:11:11
\.


--
-- TOC entry 2951 (class 0 OID 16433)
-- Dependencies: 201
-- Data for Name: tblJobHistory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblJobHistory" (id, message, "createdOn", "createdBy", "jobId", session) FROM stdin;
11434	{"message":"Execution started","level":2}	2019-07-07 21:03:41.595884	testBot	426	\N
11435	{"message":"Execution started","level":2}	2019-07-07 21:03:41.60958	testBot	426	\N
11436	{"message":"Executing step 'step1'","level":2}	2019-07-07 21:03:41.627977	testBot	426	\N
11437	{"message":"Executing step 'step1'","level":2}	2019-07-07 21:03:41.628362	testBot	426	\N
11438	{"message":"Failed to execute step 'step1'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-07 21:03:41.641815	testBot	426	\N
11439	{"message":"Failed to execute step 'step1'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-07 21:03:41.64309	testBot	426	\N
11440	{"message":"Executing step 'step2'","level":2}	2019-07-07 21:03:41.653654	testBot	426	\N
11441	{"message":"Executing step 'step2'","level":2}	2019-07-07 21:03:41.654923	testBot	426	\N
11442	{"message":"Failed to execute step 'step2'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-07 21:03:41.65987	testBot	426	\N
11443	{"message":"Failed to execute step 'step2'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-07 21:03:41.660161	testBot	426	\N
11444	{"message":"Execution finished","level":2}	2019-07-07 21:03:41.662217	testBot	426	\N
11445	{"message":"Execution finished","level":2}	2019-07-07 21:03:41.663395	testBot	426	\N
11446	{"message":"Execution started","level":2}	2019-07-08 19:37:31.275751	testBot	426	\N
11447	{"message":"Execution started","level":2}	2019-07-08 19:37:31.288233	testBot	426	\N
11448	{"message":"Executing step 'step1'","level":2}	2019-07-08 19:37:31.306167	testBot	426	\N
11449	{"message":"Executing step 'step1'","level":2}	2019-07-08 19:37:31.306389	testBot	426	\N
11450	{"message":"Failed to execute step 'step1'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-08 19:37:31.324086	testBot	426	\N
11451	{"message":"Failed to execute step 'step1'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-08 19:37:31.32531	testBot	426	\N
11452	{"message":"Executing step 'step2'","level":2}	2019-07-08 19:37:31.3261	testBot	426	\N
11453	{"message":"Executing step 'step2'","level":2}	2019-07-08 19:37:31.328552	testBot	426	\N
11454	{"message":"Failed to execute step 'step2'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-08 19:37:31.330423	testBot	426	\N
11455	{"message":"Execution finished","level":2}	2019-07-08 19:37:31.333117	testBot	426	\N
11456	{"message":"Failed to execute step 'step2'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-08 19:37:31.334339	testBot	426	\N
11457	{"message":"Execution finished","level":2}	2019-07-08 19:37:31.336684	testBot	426	\N
11458	{"message":"Execution started","level":2}	2019-07-17 18:35:01.205126	testBot	426	\N
11459	{"message":"Execution started","level":2}	2019-07-17 18:35:01.21757	testBot	426	\N
11460	{"message":"Executing step 'step1'","level":2}	2019-07-17 18:35:01.235906	testBot	426	\N
11461	{"message":"Executing step 'step1'","level":2}	2019-07-17 18:35:01.238361	testBot	426	\N
11462	{"message":"Failed to execute step 'step1'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:35:01.241935	testBot	426	\N
11463	{"message":"Failed to execute step 'step1'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:35:01.2458	testBot	426	\N
11464	{"message":"Executing step 'step2'","level":2}	2019-07-17 18:35:01.256067	testBot	426	\N
11465	{"message":"Executing step 'step2'","level":2}	2019-07-17 18:35:01.257631	testBot	426	\N
11466	{"message":"Failed to execute step 'step2'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:35:01.26004	testBot	426	\N
11467	{"message":"Execution finished","level":2}	2019-07-17 18:35:01.262938	testBot	426	\N
11468	{"message":"Failed to execute step 'step2'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:35:01.263166	testBot	426	\N
11469	{"message":"Execution finished","level":2}	2019-07-17 18:35:01.26657	testBot	426	\N
11470	{"message":"Execution started","level":2}	2019-07-17 18:39:41.094787	testBot	426	\N
11471	{"message":"Execution started","level":2}	2019-07-17 18:39:41.107543	testBot	426	\N
11472	{"message":"Executing step 'step1'","level":2}	2019-07-17 18:39:41.119256	testBot	426	\N
11473	{"message":"Executing step 'step1'","level":2}	2019-07-17 18:39:41.125552	testBot	426	\N
11474	{"message":"Failed to execute step 'step1'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:39:41.130415	testBot	426	\N
11475	{"message":"Failed to execute step 'step1'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:39:41.133519	testBot	426	\N
11476	{"message":"Executing step 'step2'","level":2}	2019-07-17 18:39:41.135287	testBot	426	\N
11477	{"message":"Executing step 'step2'","level":2}	2019-07-17 18:39:41.136235	testBot	426	\N
11478	{"message":"Failed to execute step 'step2'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:39:41.139347	testBot	426	\N
11479	{"message":"Failed to execute step 'step2'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:39:41.140058	testBot	426	\N
11480	{"message":"Execution finished","level":2}	2019-07-17 18:39:41.141822	testBot	426	\N
11481	{"message":"Execution finished","level":2}	2019-07-17 18:39:41.142482	testBot	426	\N
11482	{"message":"Execution started","level":2}	2019-07-17 18:44:11.196768	testBot	426	\N
11483	{"message":"Execution started","level":2}	2019-07-17 18:44:11.209506	testBot	426	\N
11484	{"message":"Executing step 'step1'","level":2}	2019-07-17 18:44:11.220657	testBot	426	\N
11485	{"message":"Executing step 'step1'","level":2}	2019-07-17 18:44:11.226899	testBot	426	\N
11486	{"message":"Failed to execute step 'step1'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:44:11.232541	testBot	426	\N
11487	{"message":"Failed to execute step 'step1'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:44:11.236292	testBot	426	\N
11488	{"message":"Executing step 'step2'","level":2}	2019-07-17 18:44:11.237248	testBot	426	\N
11489	{"message":"Executing step 'step2'","level":2}	2019-07-17 18:44:11.238792	testBot	426	\N
11490	{"message":"Failed to execute step 'step2'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:44:11.242421	testBot	426	\N
11491	{"message":"Failed to execute step 'step2'","error":"connect ECONNREFUSED 127.0.0.1:8080","level":0}	2019-07-17 18:44:11.243983	testBot	426	\N
11492	{"message":"Execution finished","level":2}	2019-07-17 18:44:11.245538	testBot	426	\N
11493	{"message":"Execution finished","level":2}	2019-07-17 18:44:11.247122	testBot	426	\N
\.


--
-- TOC entry 2954 (class 0 OID 16444)
-- Dependencies: 204
-- Data for Name: tblLog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblLog" (id, type, message, "createdOn", "createdBy") FROM stdin;
3823	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:34:51)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-07-07 21:03:41.641045	1
3825	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:34:51)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-07-08 19:37:31.323207	1
3827	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:34:51)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-07-17 18:35:01.249528	1
3829	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:34:51)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-07-17 18:39:41.137744	1
3831	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:34:51)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-07-17 18:44:11.239929	1
\.


--
-- TOC entry 2956 (class 0 OID 16453)
-- Dependencies: 206
-- Data for Name: tblRunHistory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblRunHistory" (id, message, "createdOn", "createdBy", session) FROM stdin;
\.


--
-- TOC entry 2969 (class 0 OID 0)
-- Dependencies: 197
-- Name: refJobStatus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."refJobStatus_id_seq"', 4, true);


--
-- TOC entry 2970 (class 0 OID 0)
-- Dependencies: 199
-- Name: tblConnection_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblConnection_id_seq"', 416, true);


--
-- TOC entry 2971 (class 0 OID 0)
-- Dependencies: 202
-- Name: tblJobHistory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblJobHistory_id_seq"', 11493, true);


--
-- TOC entry 2972 (class 0 OID 0)
-- Dependencies: 203
-- Name: tblJob_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblJob_Id_seq"', 557, true);


--
-- TOC entry 2973 (class 0 OID 0)
-- Dependencies: 205
-- Name: tblLog_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblLog_Id_seq"', 3831, true);


--
-- TOC entry 2974 (class 0 OID 0)
-- Dependencies: 207
-- Name: tblRunHistory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblRunHistory_id_seq"', 7665, true);


--
-- TOC entry 2812 (class 2606 OID 16469)
-- Name: refJobStatus refJobStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."refJobStatus"
    ADD CONSTRAINT "refJobStatus_pkey" PRIMARY KEY (id);


--
-- TOC entry 2814 (class 2606 OID 16471)
-- Name: tblConnection tblConnection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblConnection"
    ADD CONSTRAINT "tblConnection_pkey" PRIMARY KEY (id);


--
-- TOC entry 2822 (class 2606 OID 16473)
-- Name: tblRunHistory tblHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblRunHistory"
    ADD CONSTRAINT "tblHistory_pkey" PRIMARY KEY (id);


--
-- TOC entry 2818 (class 2606 OID 16475)
-- Name: tblJobHistory tblJobHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory"
    ADD CONSTRAINT "tblJobHistory_pkey" PRIMARY KEY (id);


--
-- TOC entry 2816 (class 2606 OID 16477)
-- Name: tblJob tblJob_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob"
    ADD CONSTRAINT "tblJob_pkey" PRIMARY KEY (id);


--
-- TOC entry 2820 (class 2606 OID 16479)
-- Name: tblLog tblLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblLog"
    ADD CONSTRAINT "tblLog_pkey" PRIMARY KEY (id);


--
-- TOC entry 2823 (class 2606 OID 16480)
-- Name: tblJob tbljob_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob"
    ADD CONSTRAINT tbljob_fk FOREIGN KEY ("statusId") REFERENCES public."refJobStatus"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2824 (class 2606 OID 16485)
-- Name: tblJobHistory tbljobhistory_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory"
    ADD CONSTRAINT tbljobhistory_fk FOREIGN KEY ("jobId") REFERENCES public."tblJob"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


-- Completed on 2019-07-17 21:44:59 MSK

--
-- PostgreSQL database dump complete
--

