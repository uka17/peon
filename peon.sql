--
-- PostgreSQL database dump
--

-- Dumped from database version 11.3 (Debian 11.3-1.pgdg90+1)
-- Dumped by pg_dump version 11.6 (Ubuntu 11.6-1.pgdg18.04+1)

-- Started on 2019-12-08 14:10:54 MSK

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
-- TOC entry 239 (class 1255 OID 49182)
-- Name: fnConnection_Count(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Count"(_filtertext text) RETURNS bigint
    LANGUAGE sql
    AS $$       
    select
		count(1) as count
	from
		"tblConnection" j
	where
		nullif("isDeleted", false) is null
		and (
			j.connection::json->>'name' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
			or j.connection::json->>'host' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
			or j.connection::json->>'port' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
			or j.connection::json->>'login' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
			or j.connection::json->>'type' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
		) 
$$;


--
-- TOC entry 237 (class 1255 OID 49183)
-- Name: fnConnection_Delete(integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Delete"(_connection_id integer, _modified_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblConnection" c SET 
		"isDeleted" = true,
		"modifiedBy" = _modified_by
	WHERE "id" = _connection_id;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 208 (class 1255 OID 16387)
-- Name: fnConnection_Insert(json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Insert"(connection json, created_by text) RETURNS integer
    LANGUAGE sql
    AS $$
    INSERT INTO public."tblConnection"("connection", "modifiedBy", "createdBy") VALUES (connection, created_by, created_by) RETURNING "id"
$$;


--
-- TOC entry 209 (class 1255 OID 16388)
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
-- TOC entry 238 (class 1255 OID 49180)
-- Name: fnConnection_SelectAll(text, text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_SelectAll"(_filtertext text, _sortcolumn text, _sortorder text, _perpage integer, _page integer) RETURNS SETOF json
    LANGUAGE plpgsql
    AS $_$ 
declare 
	sort_expression VARCHAR(256) := null;
begin 	
	sort_expression :=	
	case regexp_replace(_sortcolumn, '[^\w]+','')
		when 'name' then 'j.connection::json->>''name'''
		when 'host' then 'j.connection::json->>''host'''
		when 'port' then 'j.connection::json->>''port'''
		when 'enabled' then 'j.connection::json->>''enabled'''
		when 'login' then 'j.connection::json->>''login'''
		when 'type' then 'j.connection::json->>''type'''
		else 'j.id'
	end;
	
	RETURN QUERY EXECUTE '         
    select
		json_agg(t.*)
	from
		(
		select
			j.id,
			j.connection::json->>''name'' as name,
			j.connection::json->>''host'' as host,
			CAST(j.connection::json->>''enabled'' as bool) as enabled,
			CAST(j.connection::json->>''port'' as integer) as port,
			j.connection::json->>''login'' as login,
			j.connection::json->>''password'' as password,
			j.connection::json->>''type'' as type,
			j."createdOn" as created_on,
			j."createdBy" as created_by,
			j."modifiedOn" as modified_on,
			j."modifiedBy" as modified_by
		from
			"tblConnection" j
		where
			nullif(j."isDeleted", false) is null
			and (
				j.connection::json->>''name'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
				or j.connection::json->>''host'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
				or j.connection::json->>''port'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
				or j.connection::json->>''login'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
				or j.connection::json->>''type'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
			)
		order by ' || sort_expression || ' ' || regexp_replace($3, '[^\w]+','') ||
		' limit ' || $4 || ' offset ' || ($5-1)*$4 || ') t;'
	USING _filtertext, _sortcolumn, _sortorder, _perpage, _page;	
end;

$_$;


--
-- TOC entry 210 (class 1255 OID 16390)
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
-- TOC entry 211 (class 1255 OID 16391)
-- Name: fnGetJobStatusId(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnGetJobStatusId"(status text) RETURNS integer
    LANGUAGE sql
    AS $$SELECT Id FROM public."refJobStatus" r where r.status = status$$;


--
-- TOC entry 212 (class 1255 OID 16392)
-- Name: fnJobHistory_Insert(json, uuid, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJobHistory_Insert"(message json, session_id uuid, job_id integer, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblJobHistory"("message", "session", "jobId", "createdBy") VALUES (message, session_id, job_id, createdBy) RETURNING "id" $$;


--
-- TOC entry 234 (class 1255 OID 49176)
-- Name: fnJob_Count(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Count"(_filtertext text) RETURNS bigint
    LANGUAGE sql
    AS $$       
    select
		count(1) as count
	from
		"tblJob" j
	where
		nullif("isDeleted", false) is null
		and (
			j.job::json->>'name' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
			or j.job::json->>'description' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
		) 
$$;


--
-- TOC entry 232 (class 1255 OID 40960)
-- Name: fnJob_Delete(integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Delete"(job_id integer, deleted_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"isDeleted" = true,
		"modifiedBy" = deleted_by
	WHERE "id" = job_id;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 233 (class 1255 OID 49152)
-- Name: fnJob_Insert(json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Insert"(job json, created_by text) RETURNS integer
    LANGUAGE sql
    AS $$
    INSERT INTO public."tblJob"("job", "modifiedBy", "createdBy") VALUES (job, created_by, created_by) RETURNING "id"
$$;


--
-- TOC entry 213 (class 1255 OID 16396)
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
-- TOC entry 236 (class 1255 OID 49175)
-- Name: fnJob_SelectAll(text, text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_SelectAll"(_filtertext text, _sortcolumn text, _sortorder text, _perpage integer, _page integer) RETURNS SETOF json
    LANGUAGE plpgsql
    AS $_$ 
declare 
	sort_expression VARCHAR(256) := null;
begin 	
	sort_expression :=	
	case regexp_replace(_sortcolumn, '[^\w]+','')
		when 'name' then 'j.job::json->>''name'''
		when 'description' then 'j.job::json->>''description'''
		when 'enabled' then 'j.job::json->>''enabled'''
		else 'j.id'
	end;
	
	RETURN QUERY EXECUTE '         
    select
		--array_to_json(array_agg(row_to_json(t)))
		json_agg(t.*)
	from
		(
		select
			j.id,
			j.job::json->>''name'' as name,
			j.job::json->>''description'' as description,
			CAST(j.job::json->>''enabled'' as bool) as enabled,
			js.status as status,
			json_array_length(j.job::json#>''{steps}'') as step_count,
			json_array_length(j.job::json#>''{schedules}'') as schedule_count,
			j."lastRunResult" as last_run_result,
			j."lastRunOn" as last_run_on,
			j."nextRun" as next_run,
			j."createdOn" as created_on,
			j."createdBy" as created_by,
			j."modifiedOn" as modified_on,
			j."modifiedBy" as modified_by
		from
			"tblJob" j
			inner join "refJobStatus" js on j."statusId" = js.id
		where
			nullif(j."isDeleted", false) is null
			and (
				j.job::json->>''name'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
				or j.job::json->>''description'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
			)
		order by ' || sort_expression || ' ' || regexp_replace($3, '[^\w]+','') ||
		' limit ' || $4 || ' offset ' || ($5-1)*$4 || ') t;'
	USING _filtertext, _sortcolumn, _sortorder, _perpage, _page;	
end;

$_$;


--
-- TOC entry 214 (class 1255 OID 16398)
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
-- TOC entry 215 (class 1255 OID 16399)
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
-- TOC entry 235 (class 1255 OID 49179)
-- Name: fnJob_UpdateLastRun(integer, boolean, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_UpdateLastRun"(_job_id integer, _success boolean, _modified_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"lastRunOn" = NOW(),
		"lastRunResult" = _success,
		"modifiedBy" = _modified_by,
		"modifiedOn" = NOW()
	WHERE "id" = _job_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 228 (class 1255 OID 16400)
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
-- TOC entry 229 (class 1255 OID 16401)
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
-- TOC entry 230 (class 1255 OID 16402)
-- Name: fnLog_Insert(integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnLog_Insert"(type integer, message text, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblLog"("type", "message", "createdBy") VALUES (type, message, createdBy) RETURNING "id" $$;


--
-- TOC entry 231 (class 1255 OID 16403)
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
-- TOC entry 2964 (class 0 OID 0)
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
-- TOC entry 2965 (class 0 OID 0)
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
    "nextRun" timestamp without time zone,
    "lastRunOn" timestamp without time zone,
    "lastRunResult" boolean
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
-- TOC entry 2966 (class 0 OID 0)
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
-- TOC entry 2967 (class 0 OID 0)
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
    "createdBy" text
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
-- TOC entry 2968 (class 0 OID 0)
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
-- TOC entry 2969 (class 0 OID 0)
-- Dependencies: 207
-- Name: tblRunHistory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblRunHistory_id_seq" OWNED BY public."tblRunHistory".id;


--
-- TOC entry 2798 (class 2604 OID 16462)
-- Name: refJobStatus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."refJobStatus" ALTER COLUMN id SET DEFAULT nextval('public."refJobStatus_id_seq"'::regclass);


--
-- TOC entry 2801 (class 2604 OID 16463)
-- Name: tblConnection id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblConnection" ALTER COLUMN id SET DEFAULT nextval('public."tblConnection_id_seq"'::regclass);


--
-- TOC entry 2805 (class 2604 OID 16464)
-- Name: tblJob id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob" ALTER COLUMN id SET DEFAULT nextval('public."tblJob_Id_seq"'::regclass);


--
-- TOC entry 2807 (class 2604 OID 16465)
-- Name: tblJobHistory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory" ALTER COLUMN id SET DEFAULT nextval('public."tblJobHistory_id_seq"'::regclass);


--
-- TOC entry 2809 (class 2604 OID 16466)
-- Name: tblLog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblLog" ALTER COLUMN id SET DEFAULT nextval('public."tblLog_Id_seq"'::regclass);


--
-- TOC entry 2811 (class 2604 OID 16467)
-- Name: tblRunHistory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblRunHistory" ALTER COLUMN id SET DEFAULT nextval('public."tblRunHistory_id_seq"'::regclass);


--
-- TOC entry 2947 (class 0 OID 16404)
-- Dependencies: 196
-- Data for Name: refJobStatus; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."refJobStatus" (id, status, "modifiedOn", "modifiedBy", "createdOn", "createdBy", "isDeleted") FROM stdin;
1	Idle	2019-05-18 00:36:30.585459	system	2019-05-18 00:36:30.585459	system	\N
2	Execution	2019-05-18 00:36:30.585459	system	2019-05-18 00:36:30.585459	system	\N
3	In progress	2019-05-18 00:36:30.585	system	2019-05-18 00:36:30.585	system	\N
\.


--
-- TOC entry 2949 (class 0 OID 16414)
-- Dependencies: 198
-- Data for Name: tblConnection; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblConnection" (id, connection, "modifiedOn", "modifiedBy", "createdOn", "createdBy", "isDeleted") FROM stdin;
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
26	{\n  "name": "btest_connection",\n  "host": "test",\n  "port": 8080,\n  "enabled": true,\n  "login": "user",\n  "password": "password",\n  "type": "mongodb"\n}	2019-05-14 20:40:10.264855	test	2019-05-14 20:40:10.244508	test	t
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
417	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 18:55:10.648487	testRobot	2019-07-17 18:55:10.648487	testRobot	\N
418	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 18:55:10.701074	testRobot	2019-07-17 18:55:10.673965	testRobot	t
419	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 19:01:00.32583	testRobot	2019-07-17 19:01:00.32583	testRobot	\N
420	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 19:01:00.380433	testRobot	2019-07-17 19:01:00.34985	testRobot	t
421	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 19:24:19.738067	testRobot	2019-07-17 19:24:19.738067	testRobot	\N
422	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 19:24:19.794854	testRobot	2019-07-17 19:24:19.764371	testRobot	t
423	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 19:32:06.432766	testRobot	2019-07-17 19:32:06.432766	testRobot	\N
438	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 18:03:36.509937	testRobot	2019-07-18 18:03:36.482575	testRobot	t
424	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 19:32:06.493222	testRobot	2019-07-17 19:32:06.462961	testRobot	t
425	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 19:32:20.317472	testRobot	2019-07-17 19:32:20.317472	testRobot	\N
439	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 18:10:42.822993	testRobot	2019-07-18 18:10:42.822993	testRobot	\N
426	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 19:32:20.367004	testRobot	2019-07-17 19:32:20.341761	testRobot	t
427	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 19:42:52.197202	testRobot	2019-07-17 19:42:52.197202	testRobot	\N
428	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-17 19:42:52.246028	testRobot	2019-07-17 19:42:52.220557	testRobot	t
429	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 17:42:42.402181	testRobot	2019-07-18 17:42:42.402181	testRobot	\N
446	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 18:18:01.281441	testRobot	2019-07-18 18:18:01.25487	testRobot	t
430	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 17:42:42.454534	testRobot	2019-07-18 17:42:42.42976	testRobot	t
431	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 17:43:48.957633	testRobot	2019-07-18 17:43:48.957633	testRobot	\N
440	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 18:10:42.872895	testRobot	2019-07-18 18:10:42.84634	testRobot	t
432	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 17:43:49.007211	testRobot	2019-07-18 17:43:48.98251	testRobot	t
433	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 17:46:30.126751	testRobot	2019-07-18 17:46:30.126751	testRobot	\N
441	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 18:13:59.92521	testRobot	2019-07-18 18:13:59.92521	testRobot	\N
434	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 17:46:30.182473	testRobot	2019-07-18 17:46:30.15501	testRobot	t
435	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 17:57:49.935048	testRobot	2019-07-18 17:57:49.935048	testRobot	\N
436	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 17:57:49.986236	testRobot	2019-07-18 17:57:49.960025	testRobot	t
437	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 18:03:36.4555	testRobot	2019-07-18 18:03:36.4555	testRobot	\N
447	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 17:52:16.461002	testRobot	2019-09-25 17:52:16.461002	testRobot	\N
442	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 18:13:59.973319	testRobot	2019-07-18 18:13:59.947434	testRobot	t
443	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 18:17:39.906704	testRobot	2019-07-18 18:17:39.906704	testRobot	\N
444	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 18:17:39.955036	testRobot	2019-07-18 18:17:39.931039	testRobot	t
445	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-07-18 18:18:01.231187	testRobot	2019-07-18 18:18:01.231187	testRobot	\N
450	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 19:30:09.238798	testRobot	2019-09-25 19:30:09.211719	testRobot	t
448	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 17:52:16.518837	testRobot	2019-09-25 17:52:16.485127	testRobot	t
449	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 19:30:09.188587	testRobot	2019-09-25 19:30:09.188587	testRobot	\N
451	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 19:33:43.316747	testRobot	2019-09-25 19:33:43.316747	testRobot	\N
452	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 19:33:43.368709	testRobot	2019-09-25 19:33:43.341565	testRobot	t
453	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 19:33:58.401087	testRobot	2019-09-25 19:33:58.401087	testRobot	\N
454	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 19:33:58.452783	testRobot	2019-09-25 19:33:58.425443	testRobot	t
455	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 19:40:38.401372	testRobot	2019-09-25 19:40:38.401372	testRobot	\N
15	{\n  "name": "atest_connection",\n  "host": "127.0.0.1",\n  "port": 8080,\n  "enabled": true,\n  "login": "user",\n  "password": "password",\n  "type": "mongodb"\n}	2019-05-14 20:35:26.047464	test	2019-05-14 20:35:26.047464	test	\N
456	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 19:40:38.455738	testRobot	2019-09-25 19:40:38.42417	testRobot	t
457	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 19:41:27.339477	testRobot	2019-09-25 19:41:27.339477	testRobot	\N
27	{\n  "name": "ctest_connection",\n  "host": "227.0.0.1",\n  "port": 8080,\n  "enabled": true,\n  "login": "user",\n  "password": "password",\n  "type": "mongodb"\n}	2019-05-14 20:40:56.644127	test	2019-05-14 20:40:56.644127	test	\N
458	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-25 19:41:27.390141	testRobot	2019-09-25 19:41:27.364582	testRobot	t
459	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-26 20:25:43.753415	testRobot	2019-09-26 20:25:43.753415	testRobot	\N
471	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 13:23:39.977738	testRobot	2019-12-01 13:23:39.977738	testRobot	\N
460	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-09-26 20:25:43.807362	testRobot	2019-09-26 20:25:43.77699	testRobot	t
461	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-11-25 17:48:51.701543	testRobot	2019-11-25 17:48:51.701543	testRobot	\N
462	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-11-25 17:48:51.755821	testRobot	2019-11-25 17:48:51.730078	testRobot	t
463	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-11-25 17:59:26.826769	testRobot	2019-11-25 17:59:26.826769	testRobot	\N
483	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 14:42:18.039873	testRobot	2019-12-01 14:42:18.039873	testRobot	\N
464	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-11-25 17:59:26.879911	testRobot	2019-11-25 17:59:26.854063	testRobot	t
465	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-11-25 18:03:59.819564	testRobot	2019-11-25 18:03:59.819564	testRobot	\N
472	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 13:23:40.051663	testRobot	2019-12-01 13:23:40.002186	testRobot	t
466	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-11-25 18:03:59.870538	testRobot	2019-11-25 18:03:59.844374	testRobot	t
467	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-11-25 18:05:05.015826	testRobot	2019-11-25 18:05:05.015826	testRobot	\N
473	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 13:25:59.891249	testRobot	2019-12-01 13:25:59.891249	testRobot	\N
468	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-11-25 18:05:05.061749	testRobot	2019-11-25 18:05:05.037976	testRobot	t
469	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 08:03:12.329349	testRobot	2019-12-01 08:03:12.329349	testRobot	\N
470	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 08:03:12.38497	testRobot	2019-12-01 08:03:12.356715	testRobot	t
478	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 13:33:18.918964	testRobot	2019-12-01 13:33:18.873355	testRobot	t
474	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 13:26:01.983752	testRobot	2019-12-01 13:25:59.914596	testRobot	t
475	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 13:26:25.240631	testRobot	2019-12-01 13:26:25.240631	testRobot	\N
479	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 13:36:31.676238	testRobot	2019-12-01 13:36:31.676238	testRobot	\N
476	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 13:26:27.324678	testRobot	2019-12-01 13:26:25.26802	testRobot	t
477	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 13:33:18.848283	testRobot	2019-12-01 13:33:18.848283	testRobot	\N
484	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 14:42:18.065782	testRobot	2019-12-01 14:42:18.065782	testRobot	\N
480	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 13:36:31.741097	testRobot	2019-12-01 13:36:31.698747	testRobot	t
481	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 14:42:04.56089	testRobot	2019-12-01 14:42:04.56089	testRobot	\N
482	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 14:42:04.584978	testRobot	2019-12-01 14:42:04.584978	testRobot	\N
485	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 14:48:00.424105	testRobot	2019-12-01 14:48:00.424105	testRobot	\N
486	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 14:48:00.457349	testRobot	2019-12-01 14:48:00.457349	testRobot	t
487	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 14:54:59.241549	testRobot	2019-12-01 14:54:59.241549	testRobot	\N
502	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:25:41.774719	testRobot	2019-12-01 15:25:41.688043	testRobot	t
488	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 14:54:59.321368	testRobot	2019-12-01 14:54:59.264652	testRobot	t
489	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 14:55:31.176762	testRobot	2019-12-01 14:55:31.176762	testRobot	\N
503	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:26:41.134715	testRobot	2019-12-01 15:26:41.134715	testRobot	\N
490	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 14:55:31.266297	testRobot	2019-12-01 14:55:31.207145	testRobot	t
491	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:16:46.130932	testRobot	2019-12-01 15:16:46.130932	testRobot	\N
492	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:16:46.206103	testRobot	2019-12-01 15:16:46.159403	testRobot	t
493	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:18:00.892152	testRobot	2019-12-01 15:18:00.892152	testRobot	\N
494	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:18:00.968338	testRobot	2019-12-01 15:18:00.920548	testRobot	t
495	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:20:38.147857	testRobot	2019-12-01 15:20:38.147857	testRobot	\N
504	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:26:41.263282	testRobot	2019-12-01 15:26:41.168596	testRobot	t
496	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:20:38.240574	testRobot	2019-12-01 15:20:38.179336	testRobot	t
497	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:20:56.289017	testRobot	2019-12-01 15:20:56.289017	testRobot	\N
505	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:31:10.641718	testRobot	2019-12-01 15:31:10.641718	testRobot	\N
498	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:20:56.376692	testRobot	2019-12-01 15:20:56.317037	testRobot	t
499	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:22:27.14526	testRobot	2019-12-01 15:22:27.14526	testRobot	\N
500	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:22:27.239507	testRobot	2019-12-01 15:22:27.169193	testRobot	t
501	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:25:41.666475	testRobot	2019-12-01 15:25:41.666475	testRobot	\N
510	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:36:55.602026	testRobot	2019-12-01 15:36:55.482165	testRobot	t
511	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:38:34.615473	testRobot	2019-12-01 15:38:34.615473	testRobot	\N
506	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:31:10.762862	testRobot	2019-12-01 15:31:10.665966	testRobot	t
507	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:34:57.322559	testRobot	2019-12-01 15:34:57.322559	testRobot	\N
508	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:34:57.450743	testRobot	2019-12-01 15:34:57.352285	testRobot	t
509	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:36:55.44977	testRobot	2019-12-01 15:36:55.44977	testRobot	\N
514	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:40:12.701179	testRobot	2019-12-01 15:40:12.591028	testRobot	t
512	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:38:34.753147	testRobot	2019-12-01 15:38:34.641811	testRobot	t
513	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:40:12.567175	testRobot	2019-12-01 15:40:12.567175	testRobot	\N
515	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:47:17.417353	testRobot	2019-12-01 15:47:17.417353	testRobot	\N
516	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:47:17.551346	testRobot	2019-12-01 15:47:17.444841	testRobot	t
517	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:53:39.880401	testRobot	2019-12-01 15:53:39.880401	testRobot	\N
518	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:53:40.017322	testRobot	2019-12-01 15:53:39.909482	testRobot	t
519	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:54:09.0304	testRobot	2019-12-01 15:54:09.0304	testRobot	\N
520	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:54:09.165499	testRobot	2019-12-01 15:54:09.06062	testRobot	t
521	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:54:33.886556	testRobot	2019-12-01 15:54:33.886556	testRobot	\N
536	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:10:10.915183	testRobot	2019-12-01 16:10:10.802924	testRobot	t
522	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:54:34.021078	testRobot	2019-12-01 15:54:33.915277	testRobot	t
523	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:54:46.342591	testRobot	2019-12-01 15:54:46.342591	testRobot	\N
537	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:13:04.502556	testRobot	2019-12-01 16:13:04.502556	testRobot	\N
524	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:54:46.484377	testRobot	2019-12-01 15:54:46.384743	testRobot	t
525	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:55:42.405819	testRobot	2019-12-01 15:55:42.405819	testRobot	\N
526	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:55:42.536039	testRobot	2019-12-01 15:55:42.430589	testRobot	t
527	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:58:25.727321	testRobot	2019-12-01 15:58:25.727321	testRobot	\N
544	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:14:34.89932	testRobot	2019-12-01 16:14:34.795704	testRobot	t
528	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 15:58:25.843849	testRobot	2019-12-01 15:58:25.753641	testRobot	t
529	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:06:14.412055	testRobot	2019-12-01 16:06:14.412055	testRobot	\N
538	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:13:04.635691	testRobot	2019-12-01 16:13:04.531383	testRobot	t
530	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:06:14.537048	testRobot	2019-12-01 16:06:14.436605	testRobot	t
531	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:06:34.326953	testRobot	2019-12-01 16:06:34.326953	testRobot	\N
539	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:13:43.481389	testRobot	2019-12-01 16:13:43.481389	testRobot	\N
532	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:06:34.45443	testRobot	2019-12-01 16:06:34.355344	testRobot	t
533	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:08:37.557736	testRobot	2019-12-01 16:08:37.557736	testRobot	\N
534	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:08:37.691416	testRobot	2019-12-01 16:08:37.586249	testRobot	t
535	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:10:10.77889	testRobot	2019-12-01 16:10:10.77889	testRobot	\N
545	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:16:10.443164	testRobot	2019-12-01 16:16:10.443164	testRobot	\N
540	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:13:43.612229	testRobot	2019-12-01 16:13:43.51317	testRobot	t
541	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:14:07.06544	testRobot	2019-12-01 16:14:07.06544	testRobot	\N
542	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:14:07.194245	testRobot	2019-12-01 16:14:07.090412	testRobot	t
543	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:14:34.771871	testRobot	2019-12-01 16:14:34.771871	testRobot	\N
548	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:18:47.456971	testRobot	2019-12-01 16:18:47.343206	testRobot	t
546	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:16:10.573666	testRobot	2019-12-01 16:16:10.468449	testRobot	t
547	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:18:47.318126	testRobot	2019-12-01 16:18:47.318126	testRobot	\N
549	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:21:45.519012	testRobot	2019-12-01 16:21:45.519012	testRobot	\N
550	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:21:45.646774	testRobot	2019-12-01 16:21:45.544378	testRobot	t
551	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:22:15.38046	testRobot	2019-12-01 16:22:15.38046	testRobot	\N
552	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:22:15.51871	testRobot	2019-12-01 16:22:15.404155	testRobot	t
553	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:38:14.842059	testRobot	2019-12-01 16:38:14.842059	testRobot	\N
568	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:44:27.229103	testRobot	2019-12-02 17:44:27.125365	testRobot	t
554	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:38:14.967549	testRobot	2019-12-01 16:38:14.865839	testRobot	t
555	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:41:31.931388	testRobot	2019-12-01 16:41:31.931388	testRobot	\N
569	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:44:40.892734	testRobot	2019-12-02 17:44:40.892734	testRobot	\N
556	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:41:32.070071	testRobot	2019-12-01 16:41:31.956755	testRobot	t
557	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:42:46.247274	testRobot	2019-12-01 16:42:46.247274	testRobot	\N
558	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-01 16:42:46.375245	testRobot	2019-12-01 16:42:46.271326	testRobot	t
559	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:40:56.492423	testRobot	2019-12-02 17:40:56.492423	testRobot	\N
576	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 18:14:07.100341	testRobot	2019-12-02 18:14:06.995486	testRobot	t
560	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:40:56.640162	testRobot	2019-12-02 17:40:56.524367	testRobot	t
561	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:42:10.148623	testRobot	2019-12-02 17:42:10.148623	testRobot	\N
570	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:44:41.020874	testRobot	2019-12-02 17:44:40.917847	testRobot	t
562	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:42:10.288441	testRobot	2019-12-02 17:42:10.186389	testRobot	t
563	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:42:32.633904	testRobot	2019-12-02 17:42:32.633904	testRobot	\N
571	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:46:22.890693	testRobot	2019-12-02 17:46:22.890693	testRobot	\N
564	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:42:32.766451	testRobot	2019-12-02 17:42:32.658428	testRobot	t
565	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:42:52.184153	testRobot	2019-12-02 17:42:52.184153	testRobot	\N
566	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:42:52.322703	testRobot	2019-12-02 17:42:52.208039	testRobot	t
567	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:44:27.096629	testRobot	2019-12-02 17:44:27.096629	testRobot	\N
577	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 18:14:49.670032	testRobot	2019-12-02 18:14:49.670032	testRobot	\N
572	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 17:46:23.025662	testRobot	2019-12-02 17:46:22.915299	testRobot	t
573	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 18:13:37.448871	testRobot	2019-12-02 18:13:37.448871	testRobot	\N
580	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 18:17:04.607093	testRobot	2019-12-02 18:17:04.497401	testRobot	t
574	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 18:13:37.586718	testRobot	2019-12-02 18:13:37.476212	testRobot	t
575	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 18:14:06.971162	testRobot	2019-12-02 18:14:06.971162	testRobot	\N
581	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 18:17:43.407459	testRobot	2019-12-02 18:17:43.407459	testRobot	\N
578	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 18:14:49.812055	testRobot	2019-12-02 18:14:49.704319	testRobot	t
579	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 18:17:04.468495	testRobot	2019-12-02 18:17:04.468495	testRobot	\N
582	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 18:17:43.544807	testRobot	2019-12-02 18:17:43.438693	testRobot	t
583	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 19:22:30.075126	testRobot	2019-12-02 19:22:30.075126	testRobot	\N
598	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:51:00.103811	testRobot	2019-12-04 18:50:59.996275	testRobot	t
584	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 19:22:30.197057	testRobot	2019-12-02 19:22:30.101227	testRobot	t
585	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 19:26:02.578041	testRobot	2019-12-02 19:26:02.578041	testRobot	\N
599	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:51:08.687368	testRobot	2019-12-04 18:51:08.687368	testRobot	\N
586	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-02 19:26:02.698891	testRobot	2019-12-02 19:26:02.606747	testRobot	t
587	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:16:20.676091	testRobot	2019-12-04 18:16:20.676091	testRobot	\N
588	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:16:20.8311	testRobot	2019-12-04 18:16:20.713571	testRobot	t
589	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:28:35.663041	testRobot	2019-12-04 18:28:35.663041	testRobot	\N
590	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:28:35.798495	testRobot	2019-12-04 18:28:35.692594	testRobot	t
591	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:29:23.336105	testRobot	2019-12-04 18:29:23.336105	testRobot	\N
600	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:51:08.816802	testRobot	2019-12-04 18:51:08.71242	testRobot	t
592	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:29:23.461956	testRobot	2019-12-04 18:29:23.359135	testRobot	t
593	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:33:47.901028	testRobot	2019-12-04 18:33:47.901028	testRobot	\N
601	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:03:24.669077	testRobot	2019-12-04 20:03:24.669077	testRobot	\N
594	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:33:48.035211	testRobot	2019-12-04 18:33:47.930177	testRobot	t
595	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:50:43.161802	testRobot	2019-12-04 18:50:43.161802	testRobot	\N
596	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:50:43.291701	testRobot	2019-12-04 18:50:43.186508	testRobot	t
597	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 18:50:59.971491	testRobot	2019-12-04 18:50:59.971491	testRobot	\N
606	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:09:39.312614	testRobot	2019-12-04 20:09:39.209809	testRobot	t
607	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:10:47.890353	testRobot	2019-12-04 20:10:47.890353	testRobot	\N
602	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:03:24.807905	testRobot	2019-12-04 20:03:24.693337	testRobot	t
603	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:06:50.977627	testRobot	2019-12-04 20:06:50.977627	testRobot	\N
608	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:10:47.921614	testRobot	2019-12-04 20:10:47.921614	testRobot	\N
604	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:06:51.115765	testRobot	2019-12-04 20:06:51.007559	testRobot	t
605	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:09:39.181153	testRobot	2019-12-04 20:09:39.181153	testRobot	\N
609	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:20:36.225869	testRobot	2019-12-04 20:20:36.225869	testRobot	\N
610	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:20:36.257645	testRobot	2019-12-04 20:20:36.257645	testRobot	\N
611	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:23:11.423683	testRobot	2019-12-04 20:23:11.423683	testRobot	\N
612	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:23:11.455807	testRobot	2019-12-04 20:23:11.455807	testRobot	\N
614	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:24:38.570076	testRobot	2019-12-04 20:24:38.570076	testRobot	\N
613	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:24:38.676496	testRobot	2019-12-04 20:24:38.544082	testRobot	t
615	{"name":"test_connection","host":"172.17.0.2","port":5432,"database":"peon","enabled":true,"login":"postgres","password":"255320","type":"postgresql"}	2019-12-04 20:25:50.318093	dummy	2019-12-04 20:25:50.318093	dummy	\N
616	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:26:52.804228	testRobot	2019-12-04 20:26:52.804228	testRobot	\N
631	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 18:24:46.703272	testRobot	2019-12-05 18:24:46.598153	testRobot	t
617	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:26:52.929699	testRobot	2019-12-04 20:26:52.830227	testRobot	t
618	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:28:27.812368	testRobot	2019-12-04 20:28:27.812368	testRobot	\N
632	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 18:31:50.683906	testRobot	2019-12-05 18:31:50.683906	testRobot	\N
619	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:28:27.955509	testRobot	2019-12-04 20:28:27.844487	testRobot	t
620	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:29:34.970457	testRobot	2019-12-04 20:29:34.970457	testRobot	\N
621	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:29:35.125228	testRobot	2019-12-04 20:29:35.000265	testRobot	t
622	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:30:34.591431	testRobot	2019-12-04 20:30:34.591431	testRobot	\N
623	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-04 20:30:34.735327	testRobot	2019-12-04 20:30:34.618196	testRobot	t
624	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 18:01:31.463938	testRobot	2019-12-05 18:01:31.463938	testRobot	\N
633	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 18:31:50.807151	testRobot	2019-12-05 18:31:50.712554	testRobot	t
625	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 18:01:31.615695	testRobot	2019-12-05 18:01:31.488007	testRobot	t
626	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 18:15:32.363989	testRobot	2019-12-05 18:15:32.363989	testRobot	\N
634	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 19:30:16.307955	testRobot	2019-12-05 19:30:16.307955	testRobot	\N
627	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 18:15:32.507278	testRobot	2019-12-05 18:15:32.389777	testRobot	t
628	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 18:19:41.75604	testRobot	2019-12-05 18:19:41.75604	testRobot	\N
629	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 18:19:41.898547	testRobot	2019-12-05 18:19:41.791131	testRobot	t
630	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 18:24:46.572661	testRobot	2019-12-05 18:24:46.572661	testRobot	\N
639	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 21:21:52.600588	testRobot	2019-12-06 21:21:52.478881	testRobot	t
640	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 21:24:50.015787	testRobot	2019-12-06 21:24:50.015787	testRobot	\N
635	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-05 19:30:16.482834	testRobot	2019-12-05 19:30:16.338483	testRobot	t
636	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 21:18:02.080619	testRobot	2019-12-06 21:18:02.080619	testRobot	\N
637	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 21:18:02.249563	testRobot	2019-12-06 21:18:02.110949	testRobot	t
638	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 21:21:52.452497	testRobot	2019-12-06 21:21:52.452497	testRobot	\N
641	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 21:24:50.158203	testRobot	2019-12-06 21:24:50.046246	testRobot	t
642	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 21:25:04.058578	testRobot	2019-12-06 21:25:04.058578	testRobot	\N
643	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 21:25:04.198924	testRobot	2019-12-06 21:25:04.091092	testRobot	t
644	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 21:27:04.304871	testRobot	2019-12-06 21:27:04.304871	testRobot	\N
645	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 21:27:04.447174	testRobot	2019-12-06 21:27:04.335134	testRobot	t
646	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 22:22:33.579804	testRobot	2019-12-06 22:22:33.579804	testRobot	\N
647	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-06 22:22:33.723498	testRobot	2019-12-06 22:22:33.612275	testRobot	t
648	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 09:51:41.295402	testRobot	2019-12-07 09:51:41.295402	testRobot	\N
649	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 09:51:41.44798	testRobot	2019-12-07 09:51:41.323389	testRobot	t
650	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 09:53:20.164701	testRobot	2019-12-07 09:53:20.164701	testRobot	\N
651	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 09:53:20.294716	testRobot	2019-12-07 09:53:20.188452	testRobot	t
652	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 09:55:23.909761	testRobot	2019-12-07 09:55:23.909761	testRobot	\N
665	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:08:54.401704	testRobot	2019-12-07 10:08:54.297495	testRobot	t
653	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 09:55:24.036492	testRobot	2019-12-07 09:55:23.933229	testRobot	t
654	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 09:59:09.574299	testRobot	2019-12-07 09:59:09.574299	testRobot	\N
666	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:15:30.401562	testRobot	2019-12-07 10:15:30.401562	testRobot	\N
655	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 09:59:09.708273	testRobot	2019-12-07 09:59:09.600765	testRobot	t
656	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:00:23.334034	testRobot	2019-12-07 10:00:23.334034	testRobot	\N
657	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:00:23.482861	testRobot	2019-12-07 10:00:23.356574	testRobot	t
658	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:01:37.966933	testRobot	2019-12-07 10:01:37.966933	testRobot	\N
659	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:01:38.095177	testRobot	2019-12-07 10:01:37.989829	testRobot	t
660	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:02:33.691807	testRobot	2019-12-07 10:02:33.691807	testRobot	\N
667	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:15:30.535716	testRobot	2019-12-07 10:15:30.425631	testRobot	t
661	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:02:33.819208	testRobot	2019-12-07 10:02:33.7144	testRobot	t
662	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:05:41.939896	testRobot	2019-12-07 10:05:41.939896	testRobot	\N
668	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:16:23.027225	testRobot	2019-12-07 10:16:23.027225	testRobot	\N
663	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:05:42.071139	testRobot	2019-12-07 10:05:41.965178	testRobot	t
664	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:08:54.27297	testRobot	2019-12-07 10:08:54.27297	testRobot	\N
669	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 10:16:23.180621	testRobot	2019-12-07 10:16:23.060947	testRobot	t
670	{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 20:40:40.493455	testRobot	2019-12-07 20:40:40.493455	testRobot	\N
671	{"name":"test_connection","host":"test","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"}	2019-12-07 20:40:40.636419	testRobot	2019-12-07 20:40:40.518782	testRobot	t
\.


--
-- TOC entry 2951 (class 0 OID 16424)
-- Dependencies: 200
-- Data for Name: tblJob; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblJob" (id, job, "modifiedOn", "modifiedBy", "createdOn", "createdBy", "isDeleted", "statusId", "nextRun", "lastRunOn", "lastRunResult") FROM stdin;
769	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:03:24.504328	testBot	2019-12-04 20:03:24.485622	testBot	\N	1	\N	\N	\N
778	{"name":"test job","description":"test job description","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:22:36.534249	dummy	2019-12-04 20:22:36.534249	dummy	\N	1	\N	\N	\N
785	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:26:52.981328	testRobot	2019-12-04 20:26:52.976083	testRobot	\N	1	2019-12-04 20:30:00	\N	\N
793	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:30:34.795222	testRobot	2019-12-04 20:30:34.790271	testRobot	\N	1	2019-12-04 20:35:00	\N	\N
786	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-04T20:30:00.000Z"}	2019-12-04 20:26:53.113155	testRobot	2019-12-04 20:26:53.030255	testRobot	t	1	2019-12-04 20:30:00	\N	\N
794	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-04T20:35:00.000Z"}	2019-12-04 20:30:34.92161	testRobot	2019-12-04 20:30:34.83947	testRobot	t	1	2019-12-04 20:35:00	\N	\N
801	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:15:42.388294	testBot	2019-12-05 18:15:41.22515	testBot	\N	1	2019-12-05 18:20:00	\N	\N
806	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:19:41.52409	testBot	2019-12-05 18:19:41.52409	testBot	\N	1	\N	\N	\N
770	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:06:51.16135	testRobot	2019-12-04 20:06:51.157667	testRobot	\N	1	2019-12-04 20:10:00	\N	\N
787	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:28:28.017565	testRobot	2019-12-04 20:28:28.011619	testRobot	\N	1	2019-12-04 20:30:00	\N	\N
771	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-04T20:10:00.000Z"}	2019-12-04 20:06:51.275754	testRobot	2019-12-04 20:06:51.208774	testRobot	t	1	2019-12-04 20:10:00	\N	\N
779	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:23:11.638097	testRobot	2019-12-04 20:23:11.638097	testRobot	\N	1	\N	\N	\N
780	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:23:11.689847	testRobot	2019-12-04 20:23:11.689847	testRobot	\N	1	\N	\N	\N
788	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-04T20:30:00.000Z"}	2019-12-04 20:28:28.145224	testRobot	2019-12-04 20:28:28.064323	testRobot	t	1	2019-12-04 20:30:00	\N	\N
795	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:01:32.595268	testBot	2019-12-05 18:01:31.177777	testBot	\N	1	2019-12-05 18:05:00	\N	\N
807	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:19:41.948981	testRobot	2019-12-05 18:19:41.945266	testRobot	\N	1	2019-12-05 18:20:00	\N	\N
802	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:17:27.055912	testBot	2019-12-05 18:17:27.055912	testBot	\N	1	\N	\N	\N
772	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:09:39.361008	testRobot	2019-12-04 20:09:39.361008	testRobot	\N	1	\N	\N	\N
773	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:09:39.410579	testRobot	2019-12-04 20:09:39.410579	testRobot	\N	1	\N	\N	\N
781	{"name":"test job","description":"test job description","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:23:22.705527	dummy	2019-12-04 20:23:22.705527	dummy	\N	1	\N	\N	\N
803	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:17:40.448576	testBot	2019-12-05 18:17:40.448576	testBot	\N	1	\N	\N	\N
789	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:29:36.132233	testBot	2019-12-04 20:29:34.732496	testBot	\N	1	2019-12-04 20:30:00	\N	\N
796	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:01:31.673031	testRobot	2019-12-05 18:01:31.667634	testRobot	\N	1	2019-12-05 18:05:00	\N	\N
797	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-05T18:05:00.000Z"}	2019-12-05 18:01:31.802162	testRobot	2019-12-05 18:01:31.720328	testRobot	t	1	2019-12-05 18:05:00	\N	\N
808	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-05T18:20:00.000Z"}	2019-12-05 18:19:42.087412	testRobot	2019-12-05 18:19:41.996306	testRobot	t	1	2019-12-05 18:20:00	\N	\N
810	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:21:01.664463	testBot	2019-12-05 18:21:01.664463	testBot	\N	1	\N	\N	\N
774	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:10:48.105066	testRobot	2019-12-04 20:10:48.105066	testRobot	\N	1	\N	\N	\N
775	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:10:48.157322	testRobot	2019-12-04 20:10:48.157322	testRobot	\N	1	\N	\N	\N
782	{"name":"test job","description":"test job description","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:23:42.519443	dummy	2019-12-04 20:23:42.519443	dummy	\N	1	\N	\N	\N
790	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:29:35.179319	testRobot	2019-12-04 20:29:35.174754	testRobot	\N	1	2019-12-04 20:30:00	\N	\N
809	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:19:51.538796	testBot	2019-12-05 18:19:51.538796	testBot	\N	1	\N	\N	\N
791	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-04T20:30:00.000Z"}	2019-12-04 20:29:35.307727	testRobot	2019-12-04 20:29:35.23159	testRobot	t	1	2019-12-04 20:30:00	\N	\N
798	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:15:33.473657	testBot	2019-12-05 18:15:32.114345	testBot	\N	1	2019-12-05 18:20:00	\N	\N
804	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:18:30.053869	testBot	2019-12-05 18:18:30.053869	testBot	\N	1	\N	\N	\N
811	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:23:22.984745	testBot	2019-12-05 18:23:22.984745	testBot	\N	1	\N	\N	\N
799	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:15:32.559512	testRobot	2019-12-05 18:15:32.555103	testRobot	\N	1	2019-12-05 18:20:00	\N	\N
792	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:30:35.768596	testBot	2019-12-04 20:30:34.348149	testBot	\N	1	2019-12-04 20:35:00	\N	\N
768	{"name":"test job","description":"test job description","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 19:57:12.147506	system	2019-12-04 19:13:25.409206	dummy	\N	1	2019-12-04 20:00:00	\N	\N
776	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:20:36.441365	testRobot	2019-12-04 20:20:36.441365	testRobot	\N	1	\N	\N	\N
777	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:20:36.493771	testRobot	2019-12-04 20:20:36.493771	testRobot	\N	1	\N	\N	\N
784	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-04T20:25:00.000Z"}	2019-12-04 20:24:38.855585	testRobot	2019-12-04 20:24:38.774448	testRobot	t	1	2019-12-04 20:25:00	\N	\N
783	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-04 20:25:36.16007	system	2019-12-04 20:24:38.720077	testRobot	\N	1	2019-12-04 20:30:00	\N	\N
800	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-05T18:20:00.000Z"}	2019-12-05 18:15:32.68474	testRobot	2019-12-05 18:15:32.606268	testRobot	t	1	2019-12-05 18:20:00	\N	\N
805	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:19:24.780994	testBot	2019-12-05 18:19:24.780994	testBot	\N	1	\N	\N	\N
815	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-05T18:25:00.000Z"}	2019-12-05 18:24:46.905383	testRobot	2019-12-05 18:24:46.808848	testRobot	t	1	2019-12-05 18:25:00	\N	\N
812	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:24:20.070896	testBot	2019-12-05 18:24:18.868935	testBot	\N	1	2019-12-05 18:25:00	\N	\N
814	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:24:46.759944	testRobot	2019-12-05 18:24:46.754713	testRobot	\N	1	2019-12-05 18:25:00	\N	\N
813	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:24:47.628372	testBot	2019-12-05 18:24:46.286696	testBot	\N	1	2019-12-05 18:25:00	\N	\N
817	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:31:50.859499	testRobot	2019-12-05 18:31:50.855461	testRobot	\N	1	2019-12-05 18:35:00	\N	\N
820	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 19:30:16.5324	testRobot	2019-12-05 19:30:16.528978	testRobot	\N	1	2019-12-05 19:35:00	\N	\N
818	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-05T18:35:00.000Z"}	2019-12-05 18:31:50.995254	testRobot	2019-12-05 18:31:50.903804	testRobot	t	1	2019-12-05 18:35:00	\N	\N
821	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-05T19:35:00.000Z"}	2019-12-05 19:30:16.680835	testRobot	2019-12-05 19:30:16.578342	testRobot	t	1	2019-12-05 19:35:00	\N	\N
824	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 19:55:11.448486	testBot	2019-12-06 19:55:11.448486	testBot	\N	1	\N	\N	\N
816	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 18:31:51.797812	testBot	2019-12-05 18:31:50.448413	testBot	\N	1	2019-12-05 18:35:00	2019-12-05 18:31:51.743144	f
819	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-05 19:30:16.067351	testBot	2019-12-05 19:30:16.067351	testBot	\N	1	\N	\N	\N
822	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 19:54:36.519992	testBot	2019-12-06 19:54:36.519992	testBot	\N	1	\N	\N	\N
823	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 19:54:44.541559	testBot	2019-12-06 19:54:44.541559	testBot	\N	1	\N	\N	\N
825	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:06:48.581579	testBot	2019-12-06 20:06:48.581579	testBot	\N	1	\N	\N	\N
826	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:07:05.530234	testBot	2019-12-06 20:07:05.530234	testBot	\N	1	\N	\N	\N
827	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:07:56.816803	testBot	2019-12-06 20:07:56.816803	testBot	\N	1	\N	\N	\N
828	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:09:12.758814	testBot	2019-12-06 20:09:12.758814	testBot	\N	1	\N	\N	\N
829	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:10:02.276163	testBot	2019-12-06 20:10:02.276163	testBot	\N	1	\N	\N	\N
830	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:11:45.127925	testBot	2019-12-06 20:11:45.127925	testBot	\N	1	\N	\N	\N
831	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:13:02.109595	testBot	2019-12-06 20:13:02.109595	testBot	\N	1	\N	\N	\N
832	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:15:49.548921	testBot	2019-12-06 20:15:49.548921	testBot	\N	1	\N	\N	\N
833	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:19:26.390827	testBot	2019-12-06 20:19:26.390827	testBot	\N	1	\N	\N	\N
834	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:19:47.543623	testBot	2019-12-06 20:19:47.543623	testBot	\N	1	\N	\N	\N
835	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:20:29.820507	testBot	2019-12-06 20:20:29.820507	testBot	\N	1	\N	\N	\N
836	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:21:29.214197	testBot	2019-12-06 20:21:29.214197	testBot	\N	1	\N	\N	\N
837	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:21:35.300196	testBot	2019-12-06 20:21:35.300196	testBot	\N	1	\N	\N	\N
838	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:22:22.393002	testBot	2019-12-06 20:22:22.393002	testBot	\N	1	\N	\N	\N
839	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:22:42.071817	testBot	2019-12-06 20:22:42.071817	testBot	\N	1	\N	\N	\N
840	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:23:07.298345	testBot	2019-12-06 20:23:07.298345	testBot	\N	1	\N	\N	\N
841	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:26:27.134705	testBot	2019-12-06 20:26:27.134705	testBot	\N	1	\N	\N	\N
842	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:27:16.200824	testBot	2019-12-06 20:27:16.200824	testBot	\N	1	\N	\N	\N
843	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:27:42.420143	testBot	2019-12-06 20:27:42.420143	testBot	\N	1	\N	\N	\N
844	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:28:03.569965	testBot	2019-12-06 20:28:03.569965	testBot	\N	1	\N	\N	\N
845	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:29:55.854184	testBot	2019-12-06 20:29:55.854184	testBot	\N	1	\N	\N	\N
846	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:30:30.039296	testBot	2019-12-06 20:30:30.039296	testBot	\N	1	\N	\N	\N
847	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:33:16.198165	testBot	2019-12-06 20:33:16.198165	testBot	\N	1	\N	\N	\N
848	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:35:14.134238	testBot	2019-12-06 20:35:14.134238	testBot	\N	1	\N	\N	\N
849	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:35:58.465739	testBot	2019-12-06 20:35:58.465739	testBot	\N	1	\N	\N	\N
850	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:36:19.041447	testBot	2019-12-06 20:36:19.041447	testBot	\N	1	\N	\N	\N
851	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:36:54.709678	testBot	2019-12-06 20:36:54.709678	testBot	\N	1	\N	\N	\N
852	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:37:21.641597	testBot	2019-12-06 20:37:21.641597	testBot	\N	1	\N	\N	\N
853	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:37:21.653096	a	2019-12-06 20:37:21.653096	a	\N	1	\N	\N	\N
854	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:39:15.885226	testBot	2019-12-06 20:39:15.885226	testBot	\N	1	\N	\N	\N
855	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:39:15.900011	a	2019-12-06 20:39:15.900011	a	\N	1	\N	\N	\N
856	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:39:36.776155	testBot	2019-12-06 20:39:36.776155	testBot	\N	1	\N	\N	\N
857	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:39:36.792369	a	2019-12-06 20:39:36.792369	a	\N	1	\N	\N	\N
858	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:41:41.092678	testBot	2019-12-06 20:41:41.092678	testBot	\N	1	\N	\N	\N
859	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:41:41.106759	a	2019-12-06 20:41:41.106759	a	\N	1	\N	\N	\N
860	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:42:45.340778	testBot	2019-12-06 20:42:45.340778	testBot	\N	1	\N	\N	\N
861	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:42:45.358406	a	2019-12-06 20:42:45.358406	a	\N	1	\N	\N	\N
862	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:43:18.036434	testBot	2019-12-06 20:43:18.036434	testBot	\N	1	\N	\N	\N
863	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:43:18.05076	a	2019-12-06 20:43:18.05076	a	\N	1	\N	\N	\N
864	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:44:09.215661	testBot	2019-12-06 20:44:09.215661	testBot	\N	1	\N	\N	\N
865	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:44:09.232463	a	2019-12-06 20:44:09.232463	a	\N	1	\N	\N	\N
866	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:50:48.431841	testBot	2019-12-06 20:50:48.431841	testBot	\N	1	\N	\N	\N
867	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:50:48.451818	a	2019-12-06 20:50:48.451818	a	\N	1	\N	\N	\N
868	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:51:00.821834	testBot	2019-12-06 20:51:00.821834	testBot	\N	1	\N	\N	\N
869	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:51:00.842921	a	2019-12-06 20:51:00.842921	a	\N	1	\N	\N	\N
870	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:51:11.773022	testBot	2019-12-06 20:51:11.773022	testBot	\N	1	\N	\N	\N
871	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:51:11.792391	a	2019-12-06 20:51:11.792391	a	\N	1	\N	\N	\N
872	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:51:42.82718	testBot	2019-12-06 20:51:42.82718	testBot	\N	1	\N	\N	\N
873	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:52:34.632381	testBot	2019-12-06 20:52:34.632381	testBot	\N	1	\N	\N	\N
874	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:52:34.64466	a	2019-12-06 20:52:34.64466	a	\N	1	\N	\N	\N
875	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:53:26.912243	testBot	2019-12-06 20:53:26.912243	testBot	\N	1	\N	\N	\N
876	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:53:26.923479	a	2019-12-06 20:53:26.923479	a	\N	1	\N	\N	\N
877	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:58:56.596161	testBot	2019-12-06 20:58:56.596161	testBot	\N	1	\N	\N	\N
878	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:58:56.614704	a	2019-12-06 20:58:56.614704	a	\N	1	\N	\N	\N
879	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 20:59:46.440574	testBot	2019-12-06 20:59:46.440574	testBot	\N	1	\N	\N	\N
880	{"jobOK":{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]},"jobNOK":{"name":"job","enabled":true,"description":"job description","steps":[],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":"aaa","dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},"jobTestCaseOK":[{"name":"2 steps 1 schedule","enabled":true,"description":"job description","steps":[{"name":"step1","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":{"gotoStep":1}}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"1 step 2 schedules","enabled":true,"description":"job description","steps":[{"name":"step1","order":1,"enabled":true,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithSuccess"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNWeek":1,"dayOfWeek":["mon","wed","fri"],"dailyFrequency":{"occursOnceAt":"11:11:11"}},{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","eachNDay":1,"dailyFrequency":{"occursOnceAt":"11:11:11"}}]},{"name":"no steps, no schedules, nothing","enabled":true,"description":"job description"},{"name":"only schedule","enabled":true,"description":"job description","schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:54:23.071Z","month":["jan","jul"],"day":1,"dailyFrequency":{"start":"11:11:11","occursEvery":{"intervalValue":1,"intervalType":"minute"}}}]}],"stepOK":{"name":"step","enabled":true,"order":1,"connection":1,"command":"command","retryAttempts":{"number":1,"interval":5},"onSucceed":"quitWithFailure","onFailure":"quitWithFailure"},"connectionOK":{"name":"test_connection","host":"127.0.0.1","port":8080,"database":"database","enabled":true,"login":"user","password":"password","type":"mongodb"},"connectionNOK":[{"name":1,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":true,"host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":123,"port":8080,"enabled":true,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":777,"login":"user","password":"password","type":"mongodb"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":123,"password":"password","type":"zzzz"},{"name":"test_connection","host":"127.0.0.1","port":8080,"enabled":true,"login":"user","password":"password","type":"zzzz"}],"testHelperCorrectObject":{"string":"string_test","number":123.123,"integer":123,"boolean":true,"array":[1,2,3],"object":{},"enum":"enum"}}	2019-12-06 20:59:46.458231	a	2019-12-06 20:59:46.458231	a	\N	1	\N	\N	\N
881	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:02:49.410997	testBot	2019-12-06 21:02:49.410997	testBot	\N	1	\N	\N	\N
882	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:03:41.903884	testBot	2019-12-06 21:03:41.903884	testBot	\N	1	\N	\N	\N
883	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:04:25.388429	testBot	2019-12-06 21:04:25.388429	testBot	\N	1	\N	\N	\N
884	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:05:05.761313	testBot	2019-12-06 21:05:05.761313	testBot	\N	1	\N	\N	\N
885	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:05:43.838834	testBot	2019-12-06 21:05:43.838834	testBot	\N	1	\N	\N	\N
886	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:06:22.011712	testBot	2019-12-06 21:06:22.011712	testBot	\N	1	\N	\N	\N
887	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:18:01.847262	testBot	2019-12-06 21:18:01.847262	testBot	\N	1	\N	\N	\N
888	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:18:02.300448	testRobot	2019-12-06 21:18:02.296158	testRobot	\N	1	2019-12-06 21:20:00	\N	\N
889	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-06T21:20:00.000Z"}	2019-12-06 21:18:02.475038	testRobot	2019-12-06 21:18:02.347225	testRobot	t	1	2019-12-06 21:20:00	\N	\N
891	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:21:52.659178	testRobot	2019-12-06 21:21:52.654786	testRobot	\N	1	2019-12-06 21:25:00	\N	\N
890	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:21:52.213547	testBot	2019-12-06 21:21:52.213547	testBot	\N	1	\N	\N	\N
895	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-06T21:25:00.000Z"}	2019-12-06 21:24:50.398118	testRobot	2019-12-06 21:24:50.261682	testRobot	t	1	2019-12-06 21:25:00	\N	\N
892	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-06T21:25:00.000Z"}	2019-12-06 21:21:52.835984	testRobot	2019-12-06 21:21:52.705161	testRobot	t	1	2019-12-06 21:25:00	\N	\N
893	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:24:49.779811	testBot	2019-12-06 21:24:49.779811	testBot	\N	1	\N	\N	\N
894	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:24:50.215205	testRobot	2019-12-06 21:24:50.210613	testRobot	\N	1	2019-12-06 21:25:00	\N	\N
896	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:25:03.807114	testBot	2019-12-06 21:25:03.807114	testBot	\N	1	\N	\N	\N
897	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:25:04.250609	testRobot	2019-12-06 21:25:04.246337	testRobot	\N	1	2019-12-06 21:30:00	\N	\N
905	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:29:49.026483	testBot	2019-12-06 21:29:49.026483	testBot	\N	1	\N	\N	\N
901	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-06T21:30:00.000Z"}	2019-12-06 21:27:04.709777	testRobot	2019-12-06 21:27:04.567113	testRobot	t	1	2019-12-06 21:30:00	\N	\N
898	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-06T21:30:00.000Z"}	2019-12-06 21:25:04.448821	testRobot	2019-12-06 21:25:04.300767	testRobot	t	1	2019-12-06 21:30:00	\N	\N
899	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:27:04.051996	testBot	2019-12-06 21:27:04.051996	testBot	\N	1	\N	\N	\N
900	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:27:04.510801	testRobot	2019-12-06 21:27:04.505945	testRobot	\N	1	2019-12-06 21:30:00	\N	\N
906	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:30:14.30516	testBot	2019-12-06 21:30:14.30516	testBot	\N	1	\N	\N	\N
902	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:27:32.225472	testBot	2019-12-06 21:27:32.225472	testBot	\N	1	\N	\N	\N
903	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:27:52.662427	testBot	2019-12-06 21:27:52.662427	testBot	\N	1	\N	\N	\N
904	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:28:58.11802	testBot	2019-12-06 21:28:58.11802	testBot	\N	1	\N	\N	\N
907	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:30:50.493734	testBot	2019-12-06 21:30:50.493734	testBot	\N	1	\N	\N	\N
908	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:31:53.280113	testBot	2019-12-06 21:31:53.280113	testBot	\N	1	\N	\N	\N
909	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:37:37.844756	testBot	2019-12-06 21:37:37.844756	testBot	\N	1	\N	\N	\N
910	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:37:59.376039	testBot	2019-12-06 21:37:59.376039	testBot	\N	1	\N	\N	\N
911	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:38:15.237582	testBot	2019-12-06 21:38:15.237582	testBot	\N	1	\N	\N	\N
912	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:38:29.309281	testBot	2019-12-06 21:38:29.309281	testBot	\N	1	\N	\N	\N
913	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:38:53.747308	testBot	2019-12-06 21:38:53.747308	testBot	\N	1	\N	\N	\N
914	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:39:37.341411	testBot	2019-12-06 21:39:37.341411	testBot	\N	1	\N	\N	\N
915	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:44:13.095017	testBot	2019-12-06 21:44:13.095017	testBot	\N	1	\N	\N	\N
916	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:50:16.830923	testBot	2019-12-06 21:50:16.830923	testBot	\N	1	\N	\N	\N
917	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:52:20.568457	testBot	2019-12-06 21:52:20.568457	testBot	\N	1	\N	\N	\N
918	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:53:15.168922	testBot	2019-12-06 21:53:15.168922	testBot	\N	1	\N	\N	\N
919	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:53:58.784277	testBot	2019-12-06 21:53:58.784277	testBot	\N	1	\N	\N	\N
920	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:55:38.617831	testBot	2019-12-06 21:55:38.617831	testBot	\N	1	\N	\N	\N
921	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:56:01.092855	testBot	2019-12-06 21:56:01.092855	testBot	\N	1	\N	\N	\N
922	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:56:16.289437	testBot	2019-12-06 21:56:16.289437	testBot	\N	1	\N	\N	\N
923	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:56:32.093413	testBot	2019-12-06 21:56:32.093413	testBot	\N	1	\N	\N	\N
924	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:56:47.251678	testBot	2019-12-06 21:56:47.251678	testBot	\N	1	\N	\N	\N
925	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:57:06.797387	testBot	2019-12-06 21:57:06.797387	testBot	\N	1	\N	\N	\N
926	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:57:51.318181	testBot	2019-12-06 21:57:51.318181	testBot	\N	1	\N	\N	\N
927	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:58:50.792482	testBot	2019-12-06 21:58:50.792482	testBot	\N	1	\N	\N	\N
928	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 21:58:58.623063	testBot	2019-12-06 21:58:58.623063	testBot	\N	1	\N	\N	\N
929	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:00:01.479739	testBot	2019-12-06 22:00:01.479739	testBot	\N	1	\N	\N	\N
930	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:00:43.505103	testBot	2019-12-06 22:00:43.505103	testBot	\N	1	\N	\N	\N
932	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:01:30.37579	testBot	2019-12-06 22:01:30.37579	testBot	\N	1	\N	\N	\N
934	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:02:13.424575	testBot	2019-12-06 22:02:13.424575	testBot	\N	1	\N	\N	\N
936	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:03:01.430451	testBot	2019-12-06 22:03:01.430451	testBot	\N	1	\N	\N	\N
938	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:03:24.474098	testBot	2019-12-06 22:03:24.474098	testBot	\N	1	\N	\N	\N
940	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:05:16.942923	testBot	2019-12-06 22:05:16.942923	testBot	\N	1	\N	\N	\N
942	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:05:24.467428	testBot	2019-12-06 22:05:24.467428	testBot	\N	1	\N	\N	\N
944	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:05:40.648445	testBot	2019-12-06 22:05:40.648445	testBot	\N	1	\N	\N	\N
946	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:06:10.782146	testBot	2019-12-06 22:06:10.782146	testBot	\N	1	\N	\N	\N
948	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:06:23.482159	testBot	2019-12-06 22:06:23.482159	testBot	\N	1	\N	\N	\N
950	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:06:37.29952	testBot	2019-12-06 22:06:37.29952	testBot	\N	1	\N	\N	\N
952	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:09:16.903153	testBot	2019-12-06 22:09:16.903153	testBot	\N	1	\N	\N	\N
954	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:11:22.696796	testBot	2019-12-06 22:11:22.696796	testBot	\N	1	\N	\N	\N
956	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:15:34.151721	testBot	2019-12-06 22:15:34.151721	testBot	\N	1	\N	\N	\N
958	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:16:23.184035	testBot	2019-12-06 22:16:23.184035	testBot	\N	1	\N	\N	\N
960	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:17:23.941318	testBot	2019-12-06 22:17:23.941318	testBot	\N	1	\N	\N	\N
962	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:17:41.102263	testBot	2019-12-06 22:17:41.102263	testBot	\N	1	\N	\N	\N
964	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:18:06.198739	testBot	2019-12-06 22:18:06.198739	testBot	\N	1	\N	\N	\N
966	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:18:23.498035	testBot	2019-12-06 22:18:23.498035	testBot	\N	1	\N	\N	\N
968	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:20:03.26268	testBot	2019-12-06 22:20:03.26268	testBot	\N	1	\N	\N	\N
970	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:21:25.67347	testBot	2019-12-06 22:21:25.67347	testBot	\N	1	\N	\N	\N
972	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:22:33.277439	testBot	2019-12-06 22:22:33.277439	testBot	\N	1	\N	\N	\N
974	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-06 22:22:33.780348	testRobot	2019-12-06 22:22:33.775514	testRobot	\N	1	2019-12-06 22:25:00	\N	\N
982	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 07:43:37.200161	testBot	2019-12-07 07:43:37.111113	testBot	\N	1	\N	\N	\N
975	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-06T22:25:00.000Z"}	2019-12-06 22:22:33.988337	testRobot	2019-12-06 22:22:33.836986	testRobot	t	1	2019-12-06 22:25:00	\N	\N
976	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 07:39:50.526359	testBot	2019-12-07 07:39:50.526359	testBot	\N	1	\N	\N	\N
978	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 07:40:23.715073	testBot	2019-12-07 07:40:23.715073	testBot	\N	1	\N	\N	\N
980	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 07:43:02.607895	testBot	2019-12-07 07:43:02.607895	testBot	\N	1	\N	\N	\N
984	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 07:43:43.924089	testBot	2019-12-07 07:43:43.833393	testBot	\N	1	\N	\N	\N
986	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 07:46:56.615722	testBot	2019-12-07 07:46:56.51991	testBot	\N	1	\N	\N	\N
988	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 07:47:57.828436	testBot	2019-12-07 07:47:57.7566	testBot	\N	1	\N	\N	\N
990	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 07:48:58.559781	testBot	2019-12-07 07:48:58.464687	testBot	\N	1	\N	\N	\N
992	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 07:50:04.782345	testBot	2019-12-07 07:50:04.67867	testBot	\N	1	\N	\N	\N
994	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 07:51:17.279945	testBot	2019-12-07 07:51:16.06259	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 07:51:17.195882	f
996	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:13:50.769108	testBot	2019-12-07 08:13:49.542811	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:13:50.686458	f
1004	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:17:16.782867	testBot	2019-12-07 08:17:15.530574	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:17:16.685976	f
998	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:15:00.687163	testBot	2019-12-07 08:14:59.456472	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:15:00.60484	f
1002	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:15:58.418043	testBot	2019-12-07 08:15:57.189803	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:15:58.336406	f
1000	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:15:43.871225	testBot	2019-12-07 08:15:42.636405	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:15:43.790759	f
1006	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:18:04.641392	testBot	2019-12-07 08:18:03.42291	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:18:04.564665	f
1010	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:22:40.24835	testBot	2019-12-07 08:22:38.927526	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:22:40.188241	f
1008	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:19:48.581789	testBot	2019-12-07 08:19:46.246545	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:19:48.523631	f
1012	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:24:19.400865	testBot	2019-12-07 08:24:18.079077	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:24:19.341564	f
1014	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:24:58.60659	testBot	2019-12-07 08:24:58.389346	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:24:58.525129	f
1016	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:26:43.73832	testBot	2019-12-07 08:26:43.73832	testBot	\N	1	\N	\N	\N
1018	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:34:03.15269	testBot	2019-12-07 08:34:02.86691	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:34:03.099784	t
1020	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:34:12.464352	testBot	2019-12-07 08:34:12.201232	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:34:12.415264	t
1026	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:40:12.884979	testBot	2019-12-07 08:40:12.365613	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:40:12.838218	f
1022	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:35:17.02339	testBot	2019-12-07 08:35:16.661262	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:35:16.97834	f
1024	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:36:47.495441	testBot	2019-12-07 08:36:47.145217	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:36:47.447591	f
1028	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 08:42:15.308625	testBot	2019-12-07 08:42:14.806202	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 08:42:15.262418	t
1030	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:05:58.36904	testBot	2019-12-07 09:05:57.774981	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:05:58.329382	t
1036	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:20:56.319122	testBot	2019-12-07 09:20:55.628867	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:20:56.283294	f
1032	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:07:09.010481	testBot	2019-12-07 09:07:08.41511	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:07:08.967585	t
1034	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:19:24.500354	testBot	2019-12-07 09:19:23.887609	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:19:24.45562	t
1040	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:29:11.478726	testBot	2019-12-07 09:29:10.721028	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:29:11.451781	t
1038	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:21:08.556666	testBot	2019-12-07 09:21:07.787428	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:21:08.51359	f
1050	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:33:27.988123	testBot	2019-12-07 09:33:27.253538	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:33:27.963386	t
1044	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:31:17.387661	testBot	2019-12-07 09:31:16.606305	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:31:17.364334	t
1042	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:29:42.49421	testBot	2019-12-07 09:29:41.714752	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:29:42.462878	t
1048	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:33:01.240941	testBot	2019-12-07 09:33:00.480256	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:33:01.213535	t
1046	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:31:31.225327	testBot	2019-12-07 09:31:30.429876	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:31:31.199093	t
1052	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:34:26.755864	testBot	2019-12-07 09:34:25.966127	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:34:26.727039	t
1054	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:35:03.594228	testBot	2019-12-07 09:35:02.833394	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:35:03.566552	t
1064	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:40:08.168918	testBot	2019-12-07 09:40:07.393321	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:40:08.141515	t
1058	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:38:04.635834	testBot	2019-12-07 09:38:03.829179	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:38:04.610671	t
1056	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:36:50.377971	testBot	2019-12-07 09:36:49.573927	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:36:50.352586	t
1062	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:39:50.709582	testBot	2019-12-07 09:39:49.931143	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:39:50.674959	t
1060	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:39:03.415685	testBot	2019-12-07 09:39:02.635166	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:39:03.391194	t
1066	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:40:54.099487	testBot	2019-12-07 09:40:53.325316	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:40:54.07345	t
1068	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:42:04.699952	testBot	2019-12-07 09:42:03.920124	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:42:04.670816	t
1078	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:51:41.118489	testBot	2019-12-07 09:51:40.328002	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:51:41.087659	t
1072	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:46:31.380074	testBot	2019-12-07 09:46:30.617363	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:46:31.353926	t
1070	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:43:23.230755	testBot	2019-12-07 09:43:22.482021	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:43:23.200116	t
1076	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:50:52.33033	testBot	2019-12-07 09:50:51.559109	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:50:52.29403	t
1074	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:48:54.397978	testBot	2019-12-07 09:48:53.62184	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:48:54.371831	t
1080	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:51:41.493328	testRobot	2019-12-07 09:51:41.489797	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1081	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 09:51:41.704084	testRobot	2019-12-07 09:51:41.543955	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1082	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:53:19.987968	testBot	2019-12-07 09:53:19.24116	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:53:19.95635	t
1084	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:53:20.346163	testRobot	2019-12-07 09:53:20.340914	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1086	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:55:23.73012	testBot	2019-12-07 09:55:22.951055	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:55:23.698716	t
1085	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 09:53:20.567758	testRobot	2019-12-07 09:53:20.395613	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1088	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:55:24.080552	testRobot	2019-12-07 09:55:24.076933	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1089	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 09:55:24.28752	testRobot	2019-12-07 09:55:24.121071	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1090	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:59:09.375857	testBot	2019-12-07 09:59:08.613389	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 09:59:09.350745	t
1092	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 09:59:09.758925	testRobot	2019-12-07 09:59:09.755424	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1097	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 10:00:23.737187	testRobot	2019-12-07 10:00:23.576071	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1094	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:00:23.123403	testBot	2019-12-07 10:00:22.363157	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 10:00:23.095312	t
1093	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 09:59:09.971683	testRobot	2019-12-07 09:59:09.802965	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1096	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:00:23.527172	testRobot	2019-12-07 10:00:23.523287	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1098	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:01:37.774724	testBot	2019-12-07 10:01:37.007004	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 10:01:37.748837	t
1100	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:01:38.139866	testRobot	2019-12-07 10:01:38.135477	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1102	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:02:33.485213	testBot	2019-12-07 10:02:32.71723	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 10:02:33.45739	t
1101	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 10:01:38.358349	testRobot	2019-12-07 10:01:38.184544	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1104	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:02:33.862169	testRobot	2019-12-07 10:02:33.858332	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1105	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 10:02:34.075721	testRobot	2019-12-07 10:02:33.904893	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1106	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:05:41.737599	testBot	2019-12-07 10:05:40.966807	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 10:05:41.710798	t
1108	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:05:42.117148	testRobot	2019-12-07 10:05:42.11321	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1113	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:08:54.071912	testBot	2019-12-07 10:08:53.264396	testBot	\N	1	2019-12-09 06:00:00	2019-12-07 10:08:54.043771	t
1109	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 10:05:42.337774	testRobot	2019-12-07 10:05:42.160291	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1110	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:06:10.597928	testBot	2019-12-07 10:06:10.597928	testBot	\N	1	\N	\N	\N
1111	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:07:27.848162	testBot	2019-12-07 10:07:27.848162	testBot	\N	1	\N	\N	\N
1112	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:08:27.447733	testBot	2019-12-07 10:08:27.447733	testBot	\N	1	\N	\N	\N
1115	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:08:54.445507	testRobot	2019-12-07 10:08:54.441453	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1116	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 10:08:54.657975	testRobot	2019-12-07 10:08:54.486604	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1117	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:15:30.186488	testBot	2019-12-07 10:15:28.371207	testBot	\N	1	\N	2019-12-07 10:15:30.151477	f
1119	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:15:30.580205	testRobot	2019-12-07 10:15:30.576566	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1120	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 10:15:30.790713	testRobot	2019-12-07 10:15:30.62176	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1121	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:16:22.833817	testBot	2019-12-07 10:16:22.006056	testBot	\N	1	\N	2019-12-07 10:16:22.799894	f
1123	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 10:16:23.22363	testRobot	2019-12-07 10:16:23.220166	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1124	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 10:16:23.432504	testRobot	2019-12-07 10:16:23.263835	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1125	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 20:40:40.305687	testBot	2019-12-07 20:40:39.47228	testBot	\N	1	\N	2019-12-07 20:40:40.274831	f
1127	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-07 20:40:40.685029	testRobot	2019-12-07 20:40:40.67683	testRobot	\N	1	2019-12-09 06:00:00	\N	\N
1128	{"name":"test","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}],"nextRun":"2019-12-09T06:00:00.000Z"}	2019-12-07 20:40:40.898637	testRobot	2019-12-07 20:40:40.728608	testRobot	t	1	2019-12-09 06:00:00	\N	\N
1130	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-08 11:10:14.853357	testBot	2019-12-08 11:10:14.754797	testBot	\N	1	2019-12-09 06:00:00	2019-12-08 11:10:14.788928	t
1129	{"name":"Test job","description":"Job created for testing purposes","enabled":true,"steps":[{"name":"step1","enabled":true,"order":1,"connection":203,"command":"select \\"fnLog_Insert\\"(1, 'Potatoes!', 'test')","retryAttempts":{"number":1,"interval":5},"onSucceed":"gotoNextStep","onFailure":"quitWithFailure"},{"name":"step2","enabled":true,"order":2,"connection":203,"command":"select \\"fnLog_I2nsert\\"(1, 'Tomatoes!', 'test')","retryAttempts":{"number":1,"interval":1},"onSucceed":"quitWithSuccess","onFailure":"quitWithFailure"}],"schedules":[{"enabled":true,"startDateTime":"2018-01-31T20:55:23.071Z","eachNWeek":1,"dayOfWeek":["mon","tue","wed","thu","fri"],"dailyFrequency":{"start":"06:00:00","occursEvery":{"intervalValue":5,"intervalType":"minute"}}}]}	2019-12-08 11:08:17.662988	testBot	2019-12-08 11:08:17.496671	testBot	\N	1	2019-12-09 06:00:00	2019-12-08 11:08:17.585081	t
\.


--
-- TOC entry 2952 (class 0 OID 16433)
-- Dependencies: 201
-- Data for Name: tblJobHistory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblJobHistory" (id, message, "createdOn", "createdBy", "jobId", session) FROM stdin;
13231	{"message":"Job (id=768) execution started by 'system'","level":2}	2019-12-04 19:57:12.03826	system	768	bc88673e-e6fb-4332-bbb0-e7696b62598c
13232	{"message":"Executing step 'step1'","level":2}	2019-12-04 19:57:12.04235	system	768	bc88673e-e6fb-4332-bbb0-e7696b62598c
13233	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 19:57:12.054227	system	768	bc88673e-e6fb-4332-bbb0-e7696b62598c
13234	{"message":"Executing step 'step2'","level":2}	2019-12-04 19:57:12.056609	system	768	bc88673e-e6fb-4332-bbb0-e7696b62598c
13235	{"message":"Step 'step2' successfully executed","rowsAffected":1,"level":2}	2019-12-04 19:57:12.066987	system	768	bc88673e-e6fb-4332-bbb0-e7696b62598c
13236	{"message":"Job (id=768) executed successfully","level":2}	2019-12-04 19:57:12.069609	system	768	bc88673e-e6fb-4332-bbb0-e7696b62598c
13238	{"message":"Job (id=769) execution started by 'testBot'","level":2}	2019-12-04 20:03:24.490633	testBot	769	\N
13239	{"message":"Job (id=783) execution started by 'system'","level":2}	2019-12-04 20:25:35.004512	system	783	6c01be37-b5fc-4a6d-8c43-c37c70387646
13240	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:35.007874	system	783	6c01be37-b5fc-4a6d-8c43-c37c70387646
13241	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:35.014643	system	784	6c01be37-b5fc-4a6d-8c43-c37c70387646
13242	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:35.017754	system	784	6c01be37-b5fc-4a6d-8c43-c37c70387646
13243	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:35.019806	system	783	6c01be37-b5fc-4a6d-8c43-c37c70387646
13244	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:35.023104	system	783	6c01be37-b5fc-4a6d-8c43-c37c70387646
13245	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:35.029496	system	784	6c01be37-b5fc-4a6d-8c43-c37c70387646
13246	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:35.031909	system	784	6c01be37-b5fc-4a6d-8c43-c37c70387646
13247	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:35.034692	system	783	6c01be37-b5fc-4a6d-8c43-c37c70387646
13248	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:35.038711	system	783	6c01be37-b5fc-4a6d-8c43-c37c70387646
13249	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:35.042405	system	784	6c01be37-b5fc-4a6d-8c43-c37c70387646
13250	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:35.044747	system	784	6c01be37-b5fc-4a6d-8c43-c37c70387646
13251	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:35.987763	system	784	9d7cc98e-4850-419d-885a-7cfc4d2b9115
13252	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:35.99869	system	784	9d7cc98e-4850-419d-885a-7cfc4d2b9115
13253	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:36.010341	system	784	9d7cc98e-4850-419d-885a-7cfc4d2b9115
13254	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:36.012729	system	784	9d7cc98e-4850-419d-885a-7cfc4d2b9115
13255	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:36.024122	system	784	9d7cc98e-4850-419d-885a-7cfc4d2b9115
13256	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:36.027103	system	784	9d7cc98e-4850-419d-885a-7cfc4d2b9115
13257	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:36.052337	system	783	6c01be37-b5fc-4a6d-8c43-c37c70387646
13258	{"message":"Job (id=783) failed'","level":0}	2019-12-04 20:25:36.057474	system	783	6c01be37-b5fc-4a6d-8c43-c37c70387646
13259	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:36.060613	system	784	6c01be37-b5fc-4a6d-8c43-c37c70387646
13260	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:36.158373	system	784	6c01be37-b5fc-4a6d-8c43-c37c70387646
13261	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:36.982547	system	784	9ed788a3-a3b2-411f-a4cd-aaaf7e6dc446
13262	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:36.9851	system	784	9ed788a3-a3b2-411f-a4cd-aaaf7e6dc446
13263	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:36.998377	system	784	9ed788a3-a3b2-411f-a4cd-aaaf7e6dc446
13264	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:37.001379	system	784	9ed788a3-a3b2-411f-a4cd-aaaf7e6dc446
13265	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:37.011656	system	784	9ed788a3-a3b2-411f-a4cd-aaaf7e6dc446
13266	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:37.014362	system	784	9ed788a3-a3b2-411f-a4cd-aaaf7e6dc446
13267	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:37.040113	system	784	9d7cc98e-4850-419d-885a-7cfc4d2b9115
13268	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:37.043391	system	784	9d7cc98e-4850-419d-885a-7cfc4d2b9115
13269	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:37.983342	system	784	c38ad994-c784-458e-920e-0053cdd1f6da
13270	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:37.992845	system	784	c38ad994-c784-458e-920e-0053cdd1f6da
13271	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:38.002125	system	784	c38ad994-c784-458e-920e-0053cdd1f6da
13272	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:38.004081	system	784	c38ad994-c784-458e-920e-0053cdd1f6da
13273	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:38.020118	system	784	c38ad994-c784-458e-920e-0053cdd1f6da
13274	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:38.02322	system	784	c38ad994-c784-458e-920e-0053cdd1f6da
13275	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:38.023975	system	784	9ed788a3-a3b2-411f-a4cd-aaaf7e6dc446
13276	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:38.02895	system	784	9ed788a3-a3b2-411f-a4cd-aaaf7e6dc446
13277	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:38.982222	system	784	23513906-908a-4a47-903f-41f1144c8b1a
13278	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:39.00189	system	784	23513906-908a-4a47-903f-41f1144c8b1a
13279	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:39.023877	system	784	23513906-908a-4a47-903f-41f1144c8b1a
13280	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:39.030242	system	784	23513906-908a-4a47-903f-41f1144c8b1a
13281	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:39.036223	system	784	c38ad994-c784-458e-920e-0053cdd1f6da
13282	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:39.039851	system	784	c38ad994-c784-458e-920e-0053cdd1f6da
13283	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:39.041732	system	784	23513906-908a-4a47-903f-41f1144c8b1a
13284	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:39.113008	system	784	23513906-908a-4a47-903f-41f1144c8b1a
13391	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-05 18:01:31.328445	testBot	795	\N
13285	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:39.987757	system	784	38e27486-6128-4e30-b670-8d531ff63fae
13286	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:39.991494	system	784	38e27486-6128-4e30-b670-8d531ff63fae
13287	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:40.001192	system	784	38e27486-6128-4e30-b670-8d531ff63fae
13288	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:40.0034	system	784	38e27486-6128-4e30-b670-8d531ff63fae
13289	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:40.011768	system	784	38e27486-6128-4e30-b670-8d531ff63fae
13290	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:40.014233	system	784	38e27486-6128-4e30-b670-8d531ff63fae
13291	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:40.125096	system	784	23513906-908a-4a47-903f-41f1144c8b1a
13292	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:40.137436	system	784	23513906-908a-4a47-903f-41f1144c8b1a
13297	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:41.018552	system	784	60b3ac92-fc23-4de8-bfa7-58b8bd2676aa
13298	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:41.022552	system	784	60b3ac92-fc23-4de8-bfa7-58b8bd2676aa
13299	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:41.025431	system	784	38e27486-6128-4e30-b670-8d531ff63fae
13300	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:41.028799	system	784	38e27486-6128-4e30-b670-8d531ff63fae
13306	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:42.032494	system	784	60b3ac92-fc23-4de8-bfa7-58b8bd2676aa
13308	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:42.03834	system	784	60b3ac92-fc23-4de8-bfa7-58b8bd2676aa
13317	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:43.999614	system	784	e2274b44-5de9-4617-9a06-6ccc4ddc9439
13318	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:44.003507	system	784	e2274b44-5de9-4617-9a06-6ccc4ddc9439
13319	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:44.016314	system	784	e2274b44-5de9-4617-9a06-6ccc4ddc9439
13320	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:44.018851	system	784	e2274b44-5de9-4617-9a06-6ccc4ddc9439
13321	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:44.029263	system	784	e2274b44-5de9-4617-9a06-6ccc4ddc9439
13322	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:44.038134	system	784	e2274b44-5de9-4617-9a06-6ccc4ddc9439
13323	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:44.042847	system	784	50b8a780-a016-4e7b-87ff-6641eab565a2
13324	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:44.046484	system	784	50b8a780-a016-4e7b-87ff-6641eab565a2
13328	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:45.052746	system	784	e2274b44-5de9-4617-9a06-6ccc4ddc9439
13330	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:45.07611	system	784	e2274b44-5de9-4617-9a06-6ccc4ddc9439
13333	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:46.002369	system	784	ea5aa0b2-1cc1-4534-baa9-e5091843cec0
13334	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:46.005274	system	784	ea5aa0b2-1cc1-4534-baa9-e5091843cec0
13335	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:46.015717	system	784	ea5aa0b2-1cc1-4534-baa9-e5091843cec0
13336	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:46.018728	system	784	ea5aa0b2-1cc1-4534-baa9-e5091843cec0
13337	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:46.027228	system	784	ea5aa0b2-1cc1-4534-baa9-e5091843cec0
13338	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:46.029514	system	784	ea5aa0b2-1cc1-4534-baa9-e5091843cec0
13339	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:46.276035	system	784	910a1b6f-5884-4941-b03a-0f80060598d2
13340	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:46.287007	system	784	910a1b6f-5884-4941-b03a-0f80060598d2
13345	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:47.039845	system	784	910c62a4-5527-49d2-a54f-37b88f392733
13347	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:47.04919	system	784	910c62a4-5527-49d2-a54f-37b88f392733
13349	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:48.005702	system	784	e9f2447e-5f0d-4cbf-9681-68ecfd3fa845
13350	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:48.008539	system	784	e9f2447e-5f0d-4cbf-9681-68ecfd3fa845
13351	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:48.024358	system	784	e9f2447e-5f0d-4cbf-9681-68ecfd3fa845
13352	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:48.026877	system	784	e9f2447e-5f0d-4cbf-9681-68ecfd3fa845
13353	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:48.036923	system	784	e9f2447e-5f0d-4cbf-9681-68ecfd3fa845
13354	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:48.039723	system	784	e9f2447e-5f0d-4cbf-9681-68ecfd3fa845
13355	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:48.062678	system	784	910c62a4-5527-49d2-a54f-37b88f392733
13356	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:48.06724	system	784	910c62a4-5527-49d2-a54f-37b88f392733
13365	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:50.004446	system	784	801893bd-203f-4a69-b248-b77f4843cb23
13366	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:50.0076	system	784	801893bd-203f-4a69-b248-b77f4843cb23
13367	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:50.018954	system	784	801893bd-203f-4a69-b248-b77f4843cb23
13368	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:50.020976	system	784	801893bd-203f-4a69-b248-b77f4843cb23
13369	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:50.029554	system	784	801893bd-203f-4a69-b248-b77f4843cb23
13370	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:50.031756	system	784	801893bd-203f-4a69-b248-b77f4843cb23
13371	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:50.044905	system	784	0c39c39a-722d-4d8d-86d9-85d029736beb
13372	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:50.048027	system	784	0c39c39a-722d-4d8d-86d9-85d029736beb
13293	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:40.987615	system	784	60b3ac92-fc23-4de8-bfa7-58b8bd2676aa
13294	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:40.992126	system	784	60b3ac92-fc23-4de8-bfa7-58b8bd2676aa
13295	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:41.004425	system	784	60b3ac92-fc23-4de8-bfa7-58b8bd2676aa
13296	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:41.007103	system	784	60b3ac92-fc23-4de8-bfa7-58b8bd2676aa
13301	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:41.999506	system	784	40a2b3dd-932b-4e75-9602-fbad2e1966ec
13302	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:42.002283	system	784	40a2b3dd-932b-4e75-9602-fbad2e1966ec
13303	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:42.014489	system	784	40a2b3dd-932b-4e75-9602-fbad2e1966ec
13304	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:42.017191	system	784	40a2b3dd-932b-4e75-9602-fbad2e1966ec
13305	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:42.029005	system	784	40a2b3dd-932b-4e75-9602-fbad2e1966ec
13307	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:42.036842	system	784	40a2b3dd-932b-4e75-9602-fbad2e1966ec
13309	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:42.999549	system	784	50b8a780-a016-4e7b-87ff-6641eab565a2
13310	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:43.002783	system	784	50b8a780-a016-4e7b-87ff-6641eab565a2
13311	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:43.01659	system	784	50b8a780-a016-4e7b-87ff-6641eab565a2
13312	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:43.019757	system	784	50b8a780-a016-4e7b-87ff-6641eab565a2
13313	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:43.029336	system	784	50b8a780-a016-4e7b-87ff-6641eab565a2
13314	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:43.032197	system	784	50b8a780-a016-4e7b-87ff-6641eab565a2
13315	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:43.050659	system	784	40a2b3dd-932b-4e75-9602-fbad2e1966ec
13316	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:43.054399	system	784	40a2b3dd-932b-4e75-9602-fbad2e1966ec
13325	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:45.001084	system	784	910a1b6f-5884-4941-b03a-0f80060598d2
13326	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:45.004829	system	784	910a1b6f-5884-4941-b03a-0f80060598d2
13327	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:45.015046	system	784	910a1b6f-5884-4941-b03a-0f80060598d2
13329	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:45.057022	system	784	910a1b6f-5884-4941-b03a-0f80060598d2
13331	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:45.085026	system	784	910a1b6f-5884-4941-b03a-0f80060598d2
13332	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:45.187573	system	784	910a1b6f-5884-4941-b03a-0f80060598d2
13341	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:47.004516	system	784	910c62a4-5527-49d2-a54f-37b88f392733
13342	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:47.012917	system	784	910c62a4-5527-49d2-a54f-37b88f392733
13343	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:47.02569	system	784	910c62a4-5527-49d2-a54f-37b88f392733
13344	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:47.028898	system	784	910c62a4-5527-49d2-a54f-37b88f392733
13346	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:47.041184	system	784	ea5aa0b2-1cc1-4534-baa9-e5091843cec0
13348	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:47.05064	system	784	ea5aa0b2-1cc1-4534-baa9-e5091843cec0
13357	{"message":"Job (id=784) execution started by 'system'","level":2}	2019-12-04 20:25:49.006657	system	784	0c39c39a-722d-4d8d-86d9-85d029736beb
13358	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:25:49.009935	system	784	0c39c39a-722d-4d8d-86d9-85d029736beb
13359	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:25:49.021115	system	784	0c39c39a-722d-4d8d-86d9-85d029736beb
13360	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:25:49.023001	system	784	0c39c39a-722d-4d8d-86d9-85d029736beb
13361	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:49.032005	system	784	0c39c39a-722d-4d8d-86d9-85d029736beb
13362	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:25:49.035411	system	784	0c39c39a-722d-4d8d-86d9-85d029736beb
13363	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:25:49.050872	system	784	e9f2447e-5f0d-4cbf-9681-68ecfd3fa845
13364	{"message":"Job (id=784) failed'","level":0}	2019-12-04 20:25:49.055268	system	784	e9f2447e-5f0d-4cbf-9681-68ecfd3fa845
13373	{"message":"Job (id=789) execution started by 'testBot'","level":2}	2019-12-04 20:29:34.740006	testBot	789	\N
13374	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:29:34.802251	testBot	789	\N
13375	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:29:34.831062	testBot	789	\N
13376	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:29:34.834508	testBot	789	\N
13377	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:29:34.860816	testBot	789	\N
13378	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:29:34.877636	testBot	789	\N
13379	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:29:35.953839	testBot	789	\N
13380	{"message":"Job (id=789) failed'","level":0}	2019-12-04 20:29:35.978607	testBot	789	\N
13381	{"message":"Job (id=792) execution started by 'testBot'","level":2}	2019-12-04 20:30:34.358163	testBot	792	\N
13382	{"message":"Executing step 'step1'","level":2}	2019-12-04 20:30:34.42328	testBot	792	\N
13383	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-04 20:30:34.452581	testBot	792	\N
13384	{"message":"Executing step 'step2'","level":2}	2019-12-04 20:30:34.456086	testBot	792	\N
13385	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:30:34.490008	testBot	792	\N
13386	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-04 20:30:34.507864	testBot	792	\N
13387	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-04 20:30:35.578602	testBot	792	\N
13388	{"message":"Job (id=792) failed'","level":0}	2019-12-04 20:30:35.727171	testBot	792	\N
13389	{"message":"Job (id=795) execution started by 'testBot'","level":2}	2019-12-05 18:01:31.199512	testBot	795	\N
13390	{"message":"Executing step 'step1'","level":2}	2019-12-05 18:01:31.2891	testBot	795	\N
13392	{"message":"Executing step 'step2'","level":2}	2019-12-05 18:01:31.334491	testBot	795	\N
13393	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:01:31.364337	testBot	795	\N
13394	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-05 18:01:31.389155	testBot	795	\N
13395	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:01:32.552667	testBot	795	\N
13396	{"message":"Job (id=795) failed'","level":0}	2019-12-05 18:01:32.563341	testBot	795	\N
13397	{"message":"Job (id=798) execution started by 'testBot'","level":2}	2019-12-05 18:15:32.123256	testBot	798	\N
13398	{"message":"Executing step 'step1'","level":2}	2019-12-05 18:15:32.126861	testBot	798	\N
13399	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-05 18:15:32.187647	testBot	798	\N
13400	{"message":"Executing step 'step2'","level":2}	2019-12-05 18:15:32.209957	testBot	798	\N
13401	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:15:32.22557	testBot	798	\N
13402	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-05 18:15:32.249546	testBot	798	\N
13403	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:15:33.324588	testBot	798	\N
13404	{"message":"Job (id=798) failed'","level":0}	2019-12-05 18:15:33.446827	testBot	798	\N
13405	{"message":"Job (id=801) execution started by 'testBot'","level":2}	2019-12-05 18:15:41.238621	testBot	801	\N
13406	{"message":"Executing step 'step1'","level":2}	2019-12-05 18:15:41.241682	testBot	801	\N
13407	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-05 18:15:41.300408	testBot	801	\N
13408	{"message":"Executing step 'step2'","level":2}	2019-12-05 18:15:41.303128	testBot	801	\N
13409	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:15:41.311505	testBot	801	\N
13410	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-05 18:15:41.313921	testBot	801	\N
13411	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:15:42.334895	testBot	801	\N
13412	{"message":"Job (id=801) failed'","level":0}	2019-12-05 18:15:42.34285	testBot	801	\N
13413	{"message":"Job (id=812) execution started by 'testBot'","level":2}	2019-12-05 18:24:18.882655	testBot	812	\N
13414	{"message":"Executing step 'step1'","level":2}	2019-12-05 18:24:18.939213	testBot	812	\N
13415	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-05 18:24:18.952646	testBot	812	\N
13416	{"message":"Executing step 'step2'","level":2}	2019-12-05 18:24:18.954904	testBot	812	\N
13417	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:24:18.968023	testBot	812	\N
13418	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-05 18:24:18.971877	testBot	812	\N
13419	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:24:19.99196	testBot	812	\N
13420	{"message":"Job (id=812) failed'","level":0}	2019-12-05 18:24:20.003061	testBot	812	\N
13421	{"message":"Job (id=813) execution started by 'testBot'","level":2}	2019-12-05 18:24:46.29623	testBot	813	\N
13422	{"message":"Executing step 'step1'","level":2}	2019-12-05 18:24:46.359511	testBot	813	\N
13423	{"message":"Job (id=813) execution started by 'testBot'","level":2}	2019-12-05 18:24:46.359884	testBot	813	\N
13424	{"message":"Executing step 'step1'","level":2}	2019-12-05 18:24:46.396352	testBot	813	\N
13425	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-05 18:24:46.423915	testBot	813	\N
13426	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-05 18:24:46.424213	testBot	813	\N
13427	{"message":"Executing step 'step2'","level":2}	2019-12-05 18:24:46.427737	testBot	813	\N
13428	{"message":"Executing step 'step2'","level":2}	2019-12-05 18:24:46.42887	testBot	813	\N
13429	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:24:46.436521	testBot	813	\N
13430	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:24:46.439638	testBot	813	\N
13431	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-05 18:24:46.457746	testBot	813	\N
13432	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-05 18:24:46.457958	testBot	813	\N
13433	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:24:47.497391	testBot	813	\N
13434	{"message":"Job (id=813) failed'","level":0}	2019-12-05 18:24:47.511081	testBot	813	\N
13435	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:24:47.511533	testBot	813	\N
13436	{"message":"Job (id=813) failed'","level":0}	2019-12-05 18:24:47.548864	testBot	813	\N
13437	{"message":"Job (id=816) execution started by 'testBot'","level":2}	2019-12-05 18:31:50.459082	testBot	816	\N
13438	{"message":"Executing step 'step1'","level":2}	2019-12-05 18:31:50.51134	testBot	816	\N
13439	{"message":"Job (id=816) execution started by 'testBot'","level":2}	2019-12-05 18:31:50.51172	testBot	816	\N
13440	{"message":"Executing step 'step1'","level":2}	2019-12-05 18:31:50.524044	testBot	816	\N
13441	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-05 18:31:50.549032	testBot	816	\N
13442	{"message":"Executing step 'step2'","level":2}	2019-12-05 18:31:50.551942	testBot	816	\N
13443	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-05 18:31:50.55385	testBot	816	\N
13444	{"message":"Executing step 'step2'","level":2}	2019-12-05 18:31:50.556461	testBot	816	\N
13445	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:31:50.5596	testBot	816	\N
13446	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-05 18:31:50.562268	testBot	816	\N
13447	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:31:50.583991	testBot	816	\N
13448	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-05 18:31:50.600509	testBot	816	\N
13449	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:31:51.633605	testBot	816	\N
13450	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-05 18:31:51.646676	testBot	816	\N
13452	{"message":"Job (id=816) failed'","level":0}	2019-12-05 18:31:51.747767	testBot	816	\N
13451	{"message":"Job (id=816) failed'","level":0}	2019-12-05 18:31:51.745198	testBot	816	\N
13454	{"message":"Job (id=994) execution started by 'testBot'","level":2}	2019-12-07 07:51:16.143983	testBot	994	\N
13455	{"message":"Executing step 'step1'","level":2}	2019-12-07 07:51:16.148823	testBot	994	\N
13456	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 07:51:16.161147	testBot	994	\N
13457	{"message":"Executing step 'step2'","level":2}	2019-12-07 07:51:16.163308	testBot	994	\N
13458	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 07:51:16.17059	testBot	994	\N
13459	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 07:51:16.172623	testBot	994	\N
13460	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 07:51:17.190918	testBot	994	\N
13461	{"message":"Job (id=994) failed'","level":0}	2019-12-07 07:51:17.202091	testBot	994	\N
13462	{"message":"Job (id=996) execution started by 'testBot'","level":2}	2019-12-07 08:13:49.628348	testBot	996	\N
13463	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:13:49.634407	testBot	996	\N
13464	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:13:49.646819	testBot	996	\N
13465	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:13:49.649322	testBot	996	\N
13466	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:13:49.658352	testBot	996	\N
13467	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:13:49.660955	testBot	996	\N
13468	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:13:50.681492	testBot	996	\N
13469	{"message":"Job (id=996) failed'","level":0}	2019-12-07 08:13:50.692882	testBot	996	\N
13470	{"message":"Job (id=998) execution started by 'testBot'","level":2}	2019-12-07 08:14:59.543201	testBot	998	\N
13471	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:14:59.548905	testBot	998	\N
13472	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:14:59.561653	testBot	998	\N
13473	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:14:59.563909	testBot	998	\N
13474	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:14:59.57246	testBot	998	\N
13475	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:14:59.574788	testBot	998	\N
13476	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:15:00.593615	testBot	998	\N
13477	{"message":"Job (id=998) failed'","level":0}	2019-12-07 08:15:00.612446	testBot	998	\N
13478	{"message":"Job (id=1000) execution started by 'testBot'","level":2}	2019-12-07 08:15:42.729295	testBot	1000	\N
13479	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:15:42.734454	testBot	1000	\N
13480	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:15:42.748206	testBot	1000	\N
13481	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:15:42.750927	testBot	1000	\N
13482	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:15:42.76188	testBot	1000	\N
13483	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:15:42.764794	testBot	1000	\N
13484	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:15:43.785931	testBot	1000	\N
13485	{"message":"Job (id=1000) failed'","level":0}	2019-12-07 08:15:43.795615	testBot	1000	\N
13486	{"message":"Job (id=1002) execution started by 'testBot'","level":2}	2019-12-07 08:15:57.274917	testBot	1002	\N
13487	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:15:57.280407	testBot	1002	\N
13488	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:15:57.290603	testBot	1002	\N
13489	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:15:57.292796	testBot	1002	\N
13490	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:15:57.302471	testBot	1002	\N
13491	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:15:57.304783	testBot	1002	\N
13492	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:15:58.324379	testBot	1002	\N
13493	{"message":"Job (id=1002) failed'","level":0}	2019-12-07 08:15:58.342208	testBot	1002	\N
13494	{"message":"Job (id=1004) execution started by 'testBot'","level":2}	2019-12-07 08:17:15.632515	testBot	1004	\N
13495	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:17:15.638341	testBot	1004	\N
13496	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:17:15.650594	testBot	1004	\N
13497	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:17:15.652648	testBot	1004	\N
13498	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:17:15.659373	testBot	1004	\N
13499	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:17:15.661496	testBot	1004	\N
13500	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:17:16.680593	testBot	1004	\N
13501	{"message":"Job (id=1004) failed'","level":0}	2019-12-07 08:17:16.693317	testBot	1004	\N
13502	{"message":"Job (id=1006) execution started by 'testBot'","level":2}	2019-12-07 08:18:03.506572	testBot	1006	\N
13503	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:18:03.512648	testBot	1006	\N
13504	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:18:03.525807	testBot	1006	\N
13505	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:18:03.527944	testBot	1006	\N
13506	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:18:03.537405	testBot	1006	\N
13507	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:18:03.540061	testBot	1006	\N
13508	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:18:04.559136	testBot	1006	\N
13509	{"message":"Job (id=1006) failed'","level":0}	2019-12-07 08:18:04.569259	testBot	1006	\N
13510	{"message":"Job (id=1008) execution started by 'testBot'","level":2}	2019-12-07 08:19:46.333331	testBot	1008	\N
13511	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:19:46.339094	testBot	1008	\N
13512	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:19:46.351391	testBot	1008	\N
13513	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:19:46.354813	testBot	1008	\N
13514	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:19:46.36318	testBot	1008	\N
13515	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:19:46.365368	testBot	1008	\N
13516	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:19:47.385418	testBot	1008	\N
13517	{"message":"Job (id=1008) failed'","level":0}	2019-12-07 08:19:47.395619	testBot	1008	\N
13518	{"message":"Job (id=1008) execution started by 'testBot'","level":2}	2019-12-07 08:19:47.474427	testBot	1008	\N
13519	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:19:47.476471	testBot	1008	\N
13520	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:19:47.487664	testBot	1008	\N
13521	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:19:47.490011	testBot	1008	\N
13522	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:19:47.499143	testBot	1008	\N
13523	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:19:47.501718	testBot	1008	\N
13524	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:19:48.518363	testBot	1008	\N
13525	{"message":"Job (id=1008) failed'","level":0}	2019-12-07 08:19:48.529259	testBot	1008	\N
13526	{"message":"Job (id=1010) execution started by 'testBot'","level":2}	2019-12-07 08:22:39.013431	testBot	1010	\N
13527	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:22:39.019011	testBot	1010	\N
13528	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:22:39.030415	testBot	1010	\N
13529	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:22:39.032543	testBot	1010	\N
13530	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:22:39.041651	testBot	1010	\N
13531	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:22:39.044263	testBot	1010	\N
13532	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:22:39.049157	testBot	1010	\N
13533	{"message":"Job (id=1010) failed'","level":0}	2019-12-07 08:22:39.055949	testBot	1010	\N
13534	{"message":"Job (id=1010) execution started by 'testBot'","level":2}	2019-12-07 08:22:39.138067	testBot	1010	\N
13535	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:22:39.140076	testBot	1010	\N
13536	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:22:39.149429	testBot	1010	\N
13537	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:22:39.15212	testBot	1010	\N
13538	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:22:39.160428	testBot	1010	\N
13539	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:22:39.162731	testBot	1010	\N
13540	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:22:40.182967	testBot	1010	\N
13541	{"message":"Job (id=1010) failed'","level":0}	2019-12-07 08:22:40.192856	testBot	1010	\N
13542	{"message":"Job (id=1012) execution started by 'testBot'","level":2}	2019-12-07 08:24:18.173813	testBot	1012	\N
13543	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:24:18.180334	testBot	1012	\N
13544	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:24:18.192556	testBot	1012	\N
13545	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:24:18.194572	testBot	1012	\N
13546	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:24:18.204598	testBot	1012	\N
13547	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:24:18.20701	testBot	1012	\N
13548	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:24:18.209614	testBot	1012	\N
13549	{"message":"Job (id=1012) failed'","level":0}	2019-12-07 08:24:18.216638	testBot	1012	\N
13550	{"message":"Job (id=1012) execution started by 'testBot'","level":2}	2019-12-07 08:24:18.292433	testBot	1012	\N
13551	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:24:18.294629	testBot	1012	\N
13552	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:24:18.303287	testBot	1012	\N
13553	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:24:18.305491	testBot	1012	\N
13554	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:24:18.314485	testBot	1012	\N
13555	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:24:18.31759	testBot	1012	\N
13556	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:24:19.336582	testBot	1012	\N
13557	{"message":"Job (id=1012) failed'","level":0}	2019-12-07 08:24:19.347772	testBot	1012	\N
13558	{"message":"Job (id=1014) execution started by 'testBot'","level":2}	2019-12-07 08:24:58.486242	testBot	1014	\N
13559	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:24:58.491603	testBot	1014	\N
13560	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:24:58.504257	testBot	1014	\N
13561	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:24:58.506395	testBot	1014	\N
13562	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:24:58.516575	testBot	1014	\N
13563	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:24:58.518965	testBot	1014	\N
13564	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:24:58.523112	testBot	1014	\N
13565	{"message":"Job (id=1014) failed'","level":0}	2019-12-07 08:24:58.530368	testBot	1014	\N
13566	{"message":"Job (id=1018) execution started by 'testBot'","level":2}	2019-12-07 08:34:02.95967	testBot	1018	\N
13567	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:34:02.965526	testBot	1018	\N
13568	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:34:02.97671	testBot	1018	\N
13569	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:34:02.979524	testBot	1018	\N
13570	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:34:02.990046	testBot	1018	\N
13571	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:34:02.993424	testBot	1018	\N
13572	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:34:02.997822	testBot	1018	\N
13573	{"message":"Job (id=1018) failed'","level":0}	2019-12-07 08:34:03.006542	testBot	1018	\N
13574	{"message":"Job (id=1018) execution started by 'testBot'","level":2}	2019-12-07 08:34:03.085915	testBot	1018	\N
13575	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:34:03.08775	testBot	1018	\N
13576	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:34:03.097432	testBot	1018	\N
13577	{"message":"Job (id=1018) executed successfully","level":2}	2019-12-07 08:34:03.102681	testBot	1018	\N
13578	{"message":"Job (id=1020) execution started by 'testBot'","level":2}	2019-12-07 08:34:12.280413	testBot	1020	\N
13579	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:34:12.284655	testBot	1020	\N
13580	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:34:12.29681	testBot	1020	\N
13581	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:34:12.299475	testBot	1020	\N
13582	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:34:12.308053	testBot	1020	\N
13583	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:34:12.310747	testBot	1020	\N
13584	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:34:12.315713	testBot	1020	\N
13585	{"message":"Job (id=1020) failed'","level":0}	2019-12-07 08:34:12.322209	testBot	1020	\N
13586	{"message":"Job (id=1020) execution started by 'testBot'","level":2}	2019-12-07 08:34:12.401785	testBot	1020	\N
13587	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:34:12.403597	testBot	1020	\N
13588	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:34:12.412672	testBot	1020	\N
13589	{"message":"Job (id=1020) executed successfully","level":2}	2019-12-07 08:34:12.417777	testBot	1020	\N
13590	{"message":"Job (id=1022) execution started by 'testBot'","level":2}	2019-12-07 08:35:16.758402	testBot	1022	\N
13591	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:35:16.765978	testBot	1022	\N
13592	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:35:16.780558	testBot	1022	\N
13593	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:35:16.782963	testBot	1022	\N
13594	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:35:16.790535	testBot	1022	\N
13595	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:35:16.792584	testBot	1022	\N
13596	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:35:16.795857	testBot	1022	\N
13597	{"message":"Job (id=1022) failed'","level":0}	2019-12-07 08:35:16.801589	testBot	1022	\N
13598	{"message":"Job (id=1022) execution started by 'testBot'","level":2}	2019-12-07 08:35:16.893783	testBot	1022	\N
13599	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:35:16.896031	testBot	1022	\N
13600	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:35:16.907375	testBot	1022	\N
13601	{"message":"Job (id=1022) executed successfully","level":2}	2019-12-07 08:35:16.913911	testBot	1022	\N
13602	{"message":"Job (id=1022) execution started by 'testBot'","level":2}	2019-12-07 08:35:16.965261	testBot	1022	\N
13603	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:35:16.967118	testBot	1022	\N
13604	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:35:16.975792	testBot	1022	\N
13605	{"message":"Job (id=1022) failed'","level":0}	2019-12-07 08:35:16.98104	testBot	1022	\N
13606	{"message":"Job (id=1024) execution started by 'testBot'","level":2}	2019-12-07 08:36:47.242646	testBot	1024	\N
13607	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:36:47.247644	testBot	1024	\N
13608	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:36:47.258537	testBot	1024	\N
13609	{"message":"Job (id=1024) executed successfully","level":2}	2019-12-07 08:36:47.265428	testBot	1024	\N
13610	{"message":"Job (id=1024) execution started by 'testBot'","level":2}	2019-12-07 08:36:47.345801	testBot	1024	\N
13611	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:36:47.347911	testBot	1024	\N
13612	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:36:47.358163	testBot	1024	\N
13613	{"message":"Job (id=1024) failed'","level":0}	2019-12-07 08:36:47.363329	testBot	1024	\N
13614	{"message":"Job (id=1024) execution started by 'testBot'","level":2}	2019-12-07 08:36:47.413811	testBot	1024	\N
13615	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:36:47.416207	testBot	1024	\N
13616	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:36:47.426502	testBot	1024	\N
13617	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:36:47.428645	testBot	1024	\N
13618	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:36:47.437587	testBot	1024	\N
13619	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:36:47.440319	testBot	1024	\N
13620	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:36:47.44529	testBot	1024	\N
13621	{"message":"Job (id=1024) failed'","level":0}	2019-12-07 08:36:47.450482	testBot	1024	\N
13622	{"message":"Job (id=1026) execution started by 'testBot'","level":2}	2019-12-07 08:40:12.454427	testBot	1026	\N
13623	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:40:12.460164	testBot	1026	\N
13624	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:40:12.47363	testBot	1026	\N
13625	{"message":"Job (id=1026) executed successfully","level":2}	2019-12-07 08:40:12.48037	testBot	1026	\N
13626	{"message":"Job (id=1026) execution started by 'testBot'","level":2}	2019-12-07 08:40:12.559813	testBot	1026	\N
13627	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:40:12.561608	testBot	1026	\N
13628	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:40:12.571226	testBot	1026	\N
13629	{"message":"Job (id=1026) failed'","level":0}	2019-12-07 08:40:12.576437	testBot	1026	\N
13630	{"message":"Job (id=1026) execution started by 'testBot'","level":2}	2019-12-07 08:40:12.627954	testBot	1026	\N
13631	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:40:12.629869	testBot	1026	\N
13632	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:40:12.6393	testBot	1026	\N
13633	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:40:12.641686	testBot	1026	\N
13634	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:40:12.649231	testBot	1026	\N
13635	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:40:12.651561	testBot	1026	\N
13636	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:40:12.654772	testBot	1026	\N
13637	{"message":"Job (id=1026) failed'","level":0}	2019-12-07 08:40:12.659428	testBot	1026	\N
13638	{"message":"Job (id=1026) execution started by 'testBot'","level":2}	2019-12-07 08:40:12.709891	testBot	1026	\N
13639	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:40:12.712345	testBot	1026	\N
13640	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:40:12.723033	testBot	1026	\N
13641	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:40:12.726472	testBot	1026	\N
13642	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:40:12.742937	testBot	1026	\N
13643	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:40:12.745095	testBot	1026	\N
13644	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:40:12.747397	testBot	1026	\N
13645	{"message":"Job (id=1026) executed successfully","level":2}	2019-12-07 08:40:12.752249	testBot	1026	\N
13646	{"message":"Job (id=1026) execution started by 'testBot'","level":2}	2019-12-07 08:40:12.807731	testBot	1026	\N
13647	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:40:12.809613	testBot	1026	\N
13648	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:40:12.820189	testBot	1026	\N
13649	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:40:12.822267	testBot	1026	\N
13650	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:40:12.831102	testBot	1026	\N
13651	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:40:12.833549	testBot	1026	\N
13652	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:40:12.835938	testBot	1026	\N
13653	{"message":"Job (id=1026) failed'","level":0}	2019-12-07 08:40:12.841204	testBot	1026	\N
13654	{"message":"Job (id=1028) execution started by 'testBot'","level":2}	2019-12-07 08:42:14.892908	testBot	1028	\N
13655	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:42:14.897936	testBot	1028	\N
13656	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:42:14.911503	testBot	1028	\N
13657	{"message":"Job (id=1028) executed successfully","level":2}	2019-12-07 08:42:14.919649	testBot	1028	\N
13658	{"message":"Job (id=1028) execution started by 'testBot'","level":2}	2019-12-07 08:42:15.002215	testBot	1028	\N
13659	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:42:15.005	testBot	1028	\N
13660	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:42:15.016891	testBot	1028	\N
13661	{"message":"Job (id=1028) failed'","level":0}	2019-12-07 08:42:15.022643	testBot	1028	\N
13662	{"message":"Job (id=1028) execution started by 'testBot'","level":2}	2019-12-07 08:42:15.074111	testBot	1028	\N
13663	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:42:15.076236	testBot	1028	\N
13664	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:42:15.086649	testBot	1028	\N
13665	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:42:15.088885	testBot	1028	\N
13666	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:42:15.099313	testBot	1028	\N
13667	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:42:15.101995	testBot	1028	\N
13668	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:42:15.106417	testBot	1028	\N
13669	{"message":"Job (id=1028) failed'","level":0}	2019-12-07 08:42:15.111782	testBot	1028	\N
13670	{"message":"Job (id=1028) execution started by 'testBot'","level":2}	2019-12-07 08:42:15.157487	testBot	1028	\N
13671	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:42:15.159558	testBot	1028	\N
13672	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:42:15.168404	testBot	1028	\N
13673	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:42:15.170676	testBot	1028	\N
13674	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:42:15.179322	testBot	1028	\N
13675	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:42:15.182058	testBot	1028	\N
13676	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:42:15.184482	testBot	1028	\N
13677	{"message":"Job (id=1028) executed successfully","level":2}	2019-12-07 08:42:15.189292	testBot	1028	\N
13678	{"message":"Job (id=1028) execution started by 'testBot'","level":2}	2019-12-07 08:42:15.238497	testBot	1028	\N
13679	{"message":"Executing step 'step1'","level":2}	2019-12-07 08:42:15.24054	testBot	1028	\N
13680	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 08:42:15.248908	testBot	1028	\N
13681	{"message":"Executing step 'step2'","level":2}	2019-12-07 08:42:15.2507	testBot	1028	\N
13682	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:42:15.256629	testBot	1028	\N
13683	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 08:42:15.258523	testBot	1028	\N
13684	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 08:42:15.260364	testBot	1028	\N
13685	{"message":"Job (id=1028) executed successfully","level":2}	2019-12-07 08:42:15.265025	testBot	1028	\N
13686	{"message":"Job (id=1030) execution started","level":2}	2019-12-07 09:05:57.871748	testBot	1030	\N
13687	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:05:57.876642	testBot	1030	\N
13688	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:05:57.889505	testBot	1030	\N
13689	{"message":"Job (id=1030) executed successfully","level":2}	2019-12-07 09:05:57.910192	testBot	1030	\N
13690	{"message":"Job (id=1030) execution started","level":2}	2019-12-07 09:05:57.987304	testBot	1030	\N
13691	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:05:57.989116	testBot	1030	\N
13692	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:05:57.99825	testBot	1030	\N
13693	{"message":"Job (id=1030) failed'","level":0}	2019-12-07 09:05:58.012766	testBot	1030	\N
13694	{"message":"Job (id=1030) execution started","level":2}	2019-12-07 09:05:58.075918	testBot	1030	\N
13695	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:05:58.078104	testBot	1030	\N
13696	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:05:58.087811	testBot	1030	\N
13697	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:05:58.089845	testBot	1030	\N
13698	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:05:58.098111	testBot	1030	\N
13699	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:05:58.100457	testBot	1030	\N
13700	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:05:58.104526	testBot	1030	\N
13701	{"message":"Job (id=1030) failed'","level":0}	2019-12-07 09:05:58.109283	testBot	1030	\N
13702	{"message":"Job (id=1030) execution started","level":2}	2019-12-07 09:05:58.157891	testBot	1030	\N
13703	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:05:58.159688	testBot	1030	\N
13704	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:05:58.167968	testBot	1030	\N
13705	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:05:58.169843	testBot	1030	\N
13706	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:05:58.177602	testBot	1030	\N
13707	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:05:58.179729	testBot	1030	\N
13708	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:05:58.182043	testBot	1030	\N
13709	{"message":"Job (id=1030) executed successfully","level":2}	2019-12-07 09:05:58.186558	testBot	1030	\N
13710	{"message":"Job (id=1030) execution started","level":2}	2019-12-07 09:05:58.228667	testBot	1030	\N
13711	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:05:58.230452	testBot	1030	\N
13712	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:05:58.23997	testBot	1030	\N
13713	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:05:58.241618	testBot	1030	\N
13714	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:05:58.249617	testBot	1030	\N
13715	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:05:58.251712	testBot	1030	\N
13716	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:05:58.253685	testBot	1030	\N
13717	{"message":"Job (id=1030) executed successfully","level":2}	2019-12-07 09:05:58.257607	testBot	1030	\N
13718	{"message":"Job (id=1030) execution started","level":2}	2019-12-07 09:05:58.302072	testBot	1030	\N
13719	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:05:58.30415	testBot	1030	\N
13720	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:05:58.313985	testBot	1030	\N
13721	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:05:58.315977	testBot	1030	\N
13722	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:05:58.323328	testBot	1030	\N
13723	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:05:58.325318	testBot	1030	\N
13724	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:05:58.327543	testBot	1030	\N
13725	{"message":"Job (id=1030) executed successfully","level":2}	2019-12-07 09:05:58.331737	testBot	1030	\N
13726	{"message":"Job (id=1032) execution started","level":2}	2019-12-07 09:07:08.507555	testBot	1032	\N
13727	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:07:08.513797	testBot	1032	\N
13728	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:07:08.525413	testBot	1032	\N
13729	{"message":"Job (id=1032) executed successfully","level":2}	2019-12-07 09:07:08.531763	testBot	1032	\N
13730	{"message":"Job (id=1032) execution started","level":2}	2019-12-07 09:07:08.611027	testBot	1032	\N
13731	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:07:08.61298	testBot	1032	\N
13732	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:07:08.622228	testBot	1032	\N
13733	{"message":"Job (id=1032) failed'","level":0}	2019-12-07 09:07:08.626846	testBot	1032	\N
13734	{"message":"Job (id=1032) execution started","level":2}	2019-12-07 09:07:08.678173	testBot	1032	\N
13735	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:07:08.680087	testBot	1032	\N
13736	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:07:08.698827	testBot	1032	\N
13737	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:07:08.701154	testBot	1032	\N
13738	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:07:08.710828	testBot	1032	\N
13739	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:07:08.713496	testBot	1032	\N
13740	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:07:08.71808	testBot	1032	\N
13741	{"message":"Job (id=1032) failed'","level":0}	2019-12-07 09:07:08.722982	testBot	1032	\N
13742	{"message":"Job (id=1032) execution started","level":2}	2019-12-07 09:07:08.768198	testBot	1032	\N
13743	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:07:08.77088	testBot	1032	\N
13744	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:07:08.780911	testBot	1032	\N
13745	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:07:08.783174	testBot	1032	\N
13746	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:07:08.790639	testBot	1032	\N
13747	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:07:08.793067	testBot	1032	\N
13748	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:07:08.795762	testBot	1032	\N
13749	{"message":"Job (id=1032) executed successfully","level":2}	2019-12-07 09:07:08.800505	testBot	1032	\N
13750	{"message":"Job (id=1032) execution started","level":2}	2019-12-07 09:07:08.850693	testBot	1032	\N
13751	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:07:08.853246	testBot	1032	\N
13752	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:07:08.862098	testBot	1032	\N
13753	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:07:08.864649	testBot	1032	\N
13754	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:07:08.871726	testBot	1032	\N
13755	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:07:08.873996	testBot	1032	\N
13756	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:07:08.87621	testBot	1032	\N
13757	{"message":"Job (id=1032) executed successfully","level":2}	2019-12-07 09:07:08.880616	testBot	1032	\N
13758	{"message":"Job (id=1032) execution started","level":2}	2019-12-07 09:07:08.926226	testBot	1032	\N
13759	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:07:08.928128	testBot	1032	\N
13760	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:07:08.937258	testBot	1032	\N
13761	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:07:08.939349	testBot	1032	\N
13762	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:07:08.94772	testBot	1032	\N
13763	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:07:08.960757	testBot	1032	\N
13764	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:07:08.965513	testBot	1032	\N
13765	{"message":"Job (id=1032) executed successfully","level":2}	2019-12-07 09:07:08.969855	testBot	1032	\N
13766	{"message":"Job (id=1034) execution started","level":2}	2019-12-07 09:19:23.990908	testBot	1034	\N
13767	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:19:23.995393	testBot	1034	\N
13768	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:19:24.007348	testBot	1034	\N
13769	{"message":"Job (id=1034) executed successfully","level":2}	2019-12-07 09:19:24.024201	testBot	1034	\N
13770	{"message":"Job (id=1034) execution started","level":2}	2019-12-07 09:19:24.122359	testBot	1034	\N
13771	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:19:24.12427	testBot	1034	\N
13772	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:19:24.134197	testBot	1034	\N
13773	{"message":"Job (id=1034) failed'","level":0}	2019-12-07 09:19:24.138553	testBot	1034	\N
13774	{"message":"Job (id=1034) execution started","level":2}	2019-12-07 09:19:24.18793	testBot	1034	\N
13775	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:19:24.189951	testBot	1034	\N
13776	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:19:24.198337	testBot	1034	\N
13777	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:19:24.2001	testBot	1034	\N
13778	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:19:24.207211	testBot	1034	\N
13779	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:19:24.209479	testBot	1034	\N
13780	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:19:24.212506	testBot	1034	\N
13781	{"message":"Job (id=1034) failed'","level":0}	2019-12-07 09:19:24.216319	testBot	1034	\N
13782	{"message":"Job (id=1034) execution started","level":2}	2019-12-07 09:19:24.263958	testBot	1034	\N
13783	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:19:24.265872	testBot	1034	\N
13784	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:19:24.273961	testBot	1034	\N
13785	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:19:24.275928	testBot	1034	\N
13786	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:19:24.284935	testBot	1034	\N
13787	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:19:24.287498	testBot	1034	\N
13788	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:19:24.295003	testBot	1034	\N
13789	{"message":"Job (id=1034) executed successfully","level":2}	2019-12-07 09:19:24.30005	testBot	1034	\N
13790	{"message":"Job (id=1034) execution started","level":2}	2019-12-07 09:19:24.349177	testBot	1034	\N
13791	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:19:24.350883	testBot	1034	\N
13792	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:19:24.361238	testBot	1034	\N
13793	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:19:24.363367	testBot	1034	\N
13794	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:19:24.370397	testBot	1034	\N
13795	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:19:24.3725	testBot	1034	\N
13796	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:19:24.374811	testBot	1034	\N
13797	{"message":"Job (id=1034) executed successfully","level":2}	2019-12-07 09:19:24.380057	testBot	1034	\N
13798	{"message":"Job (id=1034) execution started","level":2}	2019-12-07 09:19:24.42761	testBot	1034	\N
13799	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:19:24.429298	testBot	1034	\N
13800	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:19:24.439852	testBot	1034	\N
13801	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:19:24.441983	testBot	1034	\N
13802	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:19:24.448958	testBot	1034	\N
13803	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:19:24.451361	testBot	1034	\N
13804	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:19:24.453771	testBot	1034	\N
13805	{"message":"Job (id=1034) executed successfully","level":2}	2019-12-07 09:19:24.458089	testBot	1034	\N
13806	{"message":"Job (id=1036) execution started","level":2}	2019-12-07 09:20:55.711116	testBot	1036	\N
13807	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:20:55.715845	testBot	1036	\N
13808	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:20:55.725048	testBot	1036	\N
13809	{"message":"Job (id=1036) executed successfully","level":2}	2019-12-07 09:20:55.73094	testBot	1036	\N
13810	{"message":"Job (id=1036) execution started","level":2}	2019-12-07 09:20:55.809159	testBot	1036	\N
13811	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:20:55.811238	testBot	1036	\N
13812	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:20:55.820556	testBot	1036	\N
13813	{"message":"Job (id=1036) failed'","level":0}	2019-12-07 09:20:55.824541	testBot	1036	\N
13814	{"message":"Job (id=1036) execution started","level":2}	2019-12-07 09:20:55.879611	testBot	1036	\N
13815	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:20:55.881926	testBot	1036	\N
13816	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:20:55.892492	testBot	1036	\N
13817	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:20:55.894716	testBot	1036	\N
13818	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:20:55.904727	testBot	1036	\N
13819	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:20:55.907156	testBot	1036	\N
13820	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:20:55.911446	testBot	1036	\N
13821	{"message":"Job (id=1036) failed'","level":0}	2019-12-07 09:20:55.916283	testBot	1036	\N
13822	{"message":"Job (id=1036) execution started","level":2}	2019-12-07 09:20:55.960829	testBot	1036	\N
13823	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:20:55.962742	testBot	1036	\N
13824	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:20:55.970338	testBot	1036	\N
13825	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:20:55.972033	testBot	1036	\N
13826	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:20:55.977985	testBot	1036	\N
13827	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:20:55.980028	testBot	1036	\N
13828	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:20:55.982147	testBot	1036	\N
13829	{"message":"Job (id=1036) executed successfully","level":2}	2019-12-07 09:20:55.986676	testBot	1036	\N
13830	{"message":"Job (id=1036) execution started","level":2}	2019-12-07 09:20:56.040823	testBot	1036	\N
13831	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:20:56.042602	testBot	1036	\N
13832	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:20:56.050751	testBot	1036	\N
13833	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:20:56.052767	testBot	1036	\N
13834	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:20:56.059228	testBot	1036	\N
13835	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:20:56.06197	testBot	1036	\N
13836	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:20:56.064206	testBot	1036	\N
13837	{"message":"Job (id=1036) executed successfully","level":2}	2019-12-07 09:20:56.068858	testBot	1036	\N
13838	{"message":"Job (id=1036) execution started","level":2}	2019-12-07 09:20:56.127392	testBot	1036	\N
13839	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:20:56.128934	testBot	1036	\N
13840	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:20:56.137891	testBot	1036	\N
13841	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:20:56.139877	testBot	1036	\N
13842	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:20:56.147182	testBot	1036	\N
13843	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:20:56.149358	testBot	1036	\N
13844	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:20:56.151717	testBot	1036	\N
13845	{"message":"Job (id=1036) executed successfully","level":2}	2019-12-07 09:20:56.156224	testBot	1036	\N
13846	{"message":"Job (id=1036) execution started","level":2}	2019-12-07 09:20:56.198135	testBot	1036	\N
13847	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:20:56.199892	testBot	1036	\N
13848	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:20:56.20731	testBot	1036	\N
13849	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:20:56.209012	testBot	1036	\N
13850	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:20:56.215305	testBot	1036	\N
13851	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:20:56.217042	testBot	1036	\N
13852	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:20:56.21887	testBot	1036	\N
13853	{"message":"Job (id=1036) executed successfully","level":2}	2019-12-07 09:20:56.222351	testBot	1036	\N
13854	{"message":"Job (id=1036) execution started","level":2}	2019-12-07 09:20:56.261109	testBot	1036	\N
13855	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:20:56.262882	testBot	1036	\N
13856	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:20:56.270246	testBot	1036	\N
13857	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:20:56.271872	testBot	1036	\N
13858	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:20:56.27809	testBot	1036	\N
13859	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:20:56.279903	testBot	1036	\N
13860	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:20:56.28169	testBot	1036	\N
13861	{"message":"Job (id=1036) failed'","level":0}	2019-12-07 09:20:56.285139	testBot	1036	\N
13862	{"message":"Job (id=1038) execution started","level":2}	2019-12-07 09:21:07.879652	testBot	1038	\N
13863	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:21:07.88565	testBot	1038	\N
13864	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:21:07.89874	testBot	1038	\N
13865	{"message":"Job (id=1038) executed successfully","level":2}	2019-12-07 09:21:07.905394	testBot	1038	\N
13866	{"message":"Job (id=1038) execution started","level":2}	2019-12-07 09:21:07.987828	testBot	1038	\N
13867	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:21:07.989976	testBot	1038	\N
13868	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:21:07.999565	testBot	1038	\N
13869	{"message":"Job (id=1038) failed'","level":0}	2019-12-07 09:21:08.004141	testBot	1038	\N
13870	{"message":"Job (id=1038) execution started","level":2}	2019-12-07 09:21:08.064868	testBot	1038	\N
13871	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:21:08.066906	testBot	1038	\N
13872	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:21:08.07666	testBot	1038	\N
13873	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:21:08.079512	testBot	1038	\N
13874	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:21:08.089865	testBot	1038	\N
13875	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:21:08.091777	testBot	1038	\N
13876	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:21:08.096279	testBot	1038	\N
13877	{"message":"Job (id=1038) failed'","level":0}	2019-12-07 09:21:08.101462	testBot	1038	\N
13878	{"message":"Job (id=1038) execution started","level":2}	2019-12-07 09:21:08.158308	testBot	1038	\N
13879	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:21:08.160752	testBot	1038	\N
13880	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:21:08.171054	testBot	1038	\N
13881	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:21:08.173477	testBot	1038	\N
13882	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:21:08.182897	testBot	1038	\N
13883	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:21:08.185524	testBot	1038	\N
13884	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:21:08.188181	testBot	1038	\N
13885	{"message":"Job (id=1038) executed successfully","level":2}	2019-12-07 09:21:08.192665	testBot	1038	\N
13886	{"message":"Job (id=1038) execution started","level":2}	2019-12-07 09:21:08.236348	testBot	1038	\N
13887	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:21:08.238328	testBot	1038	\N
13888	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:21:08.254803	testBot	1038	\N
13889	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:21:08.257461	testBot	1038	\N
13890	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:21:08.267993	testBot	1038	\N
13891	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:21:08.270534	testBot	1038	\N
13892	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:21:08.272888	testBot	1038	\N
13893	{"message":"Job (id=1038) executed successfully","level":2}	2019-12-07 09:21:08.277715	testBot	1038	\N
13894	{"message":"Job (id=1038) execution started","level":2}	2019-12-07 09:21:08.323205	testBot	1038	\N
13895	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:21:08.325172	testBot	1038	\N
13896	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:21:08.334774	testBot	1038	\N
13897	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:21:08.336881	testBot	1038	\N
13898	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:21:08.34338	testBot	1038	\N
13899	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:21:08.345505	testBot	1038	\N
13900	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:21:08.347639	testBot	1038	\N
13901	{"message":"Job (id=1038) executed successfully","level":2}	2019-12-07 09:21:08.351453	testBot	1038	\N
13902	{"message":"Job (id=1038) execution started","level":2}	2019-12-07 09:21:08.394103	testBot	1038	\N
13903	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:21:08.396186	testBot	1038	\N
13904	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:21:08.407096	testBot	1038	\N
13905	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:21:08.409178	testBot	1038	\N
13906	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:21:08.41771	testBot	1038	\N
13907	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:21:08.419948	testBot	1038	\N
13908	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:21:08.422303	testBot	1038	\N
13909	{"message":"Job (id=1038) executed successfully","level":2}	2019-12-07 09:21:08.426943	testBot	1038	\N
13910	{"message":"Job (id=1038) execution started","level":2}	2019-12-07 09:21:08.479901	testBot	1038	\N
13911	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:21:08.482704	testBot	1038	\N
13912	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:21:08.494533	testBot	1038	\N
13913	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:21:08.497711	testBot	1038	\N
13914	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:21:08.505653	testBot	1038	\N
13915	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:21:08.508336	testBot	1038	\N
13916	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:21:08.511093	testBot	1038	\N
13917	{"message":"Job (id=1038) failed'","level":0}	2019-12-07 09:21:08.51745	testBot	1038	\N
13918	{"message":"Job (id=1040) execution started","level":2}	2019-12-07 09:29:10.810682	testBot	1040	\N
13919	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:10.816668	testBot	1040	\N
13920	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:10.828392	testBot	1040	\N
13921	{"message":"Job (id=1040) executed successfully","level":2}	2019-12-07 09:29:10.835481	testBot	1040	\N
13922	{"message":"Job (id=1040) execution started","level":2}	2019-12-07 09:29:10.911834	testBot	1040	\N
13923	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:10.913816	testBot	1040	\N
13924	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:10.9238	testBot	1040	\N
13925	{"message":"Job (id=1040) failed'","level":0}	2019-12-07 09:29:10.929404	testBot	1040	\N
13926	{"message":"Job (id=1040) execution started","level":2}	2019-12-07 09:29:10.981813	testBot	1040	\N
13927	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:10.98378	testBot	1040	\N
13928	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:10.992557	testBot	1040	\N
13929	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:10.994557	testBot	1040	\N
13930	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:11.002299	testBot	1040	\N
13931	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:11.004974	testBot	1040	\N
13932	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:11.010402	testBot	1040	\N
13933	{"message":"Job (id=1040) failed'","level":0}	2019-12-07 09:29:11.015954	testBot	1040	\N
13934	{"message":"Job (id=1040) execution started","level":2}	2019-12-07 09:29:11.070978	testBot	1040	\N
13935	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:11.073065	testBot	1040	\N
13936	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:11.08271	testBot	1040	\N
13937	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:11.085806	testBot	1040	\N
13938	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:11.095973	testBot	1040	\N
13939	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:11.098424	testBot	1040	\N
13940	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:11.10081	testBot	1040	\N
13941	{"message":"Job (id=1040) executed successfully","level":2}	2019-12-07 09:29:11.10554	testBot	1040	\N
13942	{"message":"Job (id=1040) execution started","level":2}	2019-12-07 09:29:11.153271	testBot	1040	\N
13943	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:11.155264	testBot	1040	\N
13944	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:11.165571	testBot	1040	\N
13945	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:11.16794	testBot	1040	\N
13946	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:11.176412	testBot	1040	\N
13947	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:11.178783	testBot	1040	\N
13948	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:11.181002	testBot	1040	\N
13949	{"message":"Job (id=1040) executed successfully","level":2}	2019-12-07 09:29:11.185654	testBot	1040	\N
13950	{"message":"Job (id=1040) execution started","level":2}	2019-12-07 09:29:11.229267	testBot	1040	\N
13951	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:11.231122	testBot	1040	\N
13952	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:11.240413	testBot	1040	\N
13953	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:11.242483	testBot	1040	\N
13954	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:11.249419	testBot	1040	\N
13955	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:11.251849	testBot	1040	\N
13956	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:29:11.254199	testBot	1040	\N
13957	{"message":"Job (id=1040) executed successfully","level":2}	2019-12-07 09:29:11.258064	testBot	1040	\N
13958	{"message":"Job (id=1040) execution started","level":2}	2019-12-07 09:29:11.301218	testBot	1040	\N
13959	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:11.303686	testBot	1040	\N
13960	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:11.311938	testBot	1040	\N
13961	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:11.313874	testBot	1040	\N
13962	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:11.322219	testBot	1040	\N
13963	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:11.324434	testBot	1040	\N
13964	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:29:11.327266	testBot	1040	\N
13965	{"message":"Job (id=1040) executed successfully","level":2}	2019-12-07 09:29:11.332303	testBot	1040	\N
13966	{"message":"Job (id=1040) execution started","level":2}	2019-12-07 09:29:11.374686	testBot	1040	\N
13967	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:11.376558	testBot	1040	\N
13968	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:11.386253	testBot	1040	\N
13969	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:11.388358	testBot	1040	\N
13970	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:11.396392	testBot	1040	\N
13971	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:11.398448	testBot	1040	\N
13972	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:29:11.400643	testBot	1040	\N
13973	{"message":"Job (id=1040) failed'","level":0}	2019-12-07 09:29:11.404777	testBot	1040	\N
13974	{"message":"Job (id=1040) execution started","level":2}	2019-12-07 09:29:11.44251	testBot	1040	\N
13975	{"message":"No any steps were found for job (id=1040)","level":0}	2019-12-07 09:29:11.444942	testBot	1040	\N
13976	{"message":"Job (id=1040) executed successfully","level":2}	2019-12-07 09:29:11.4541	testBot	1040	\N
13977	{"message":"Job (id=1042) execution started","level":2}	2019-12-07 09:29:41.802227	testBot	1042	\N
13978	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:41.80821	testBot	1042	\N
13979	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:41.820687	testBot	1042	\N
13980	{"message":"Job (id=1042) executed successfully","level":2}	2019-12-07 09:29:41.826763	testBot	1042	\N
13981	{"message":"Job (id=1042) execution started","level":2}	2019-12-07 09:29:41.908982	testBot	1042	\N
13982	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:41.911087	testBot	1042	\N
13983	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:41.921083	testBot	1042	\N
13984	{"message":"Job (id=1042) failed'","level":0}	2019-12-07 09:29:41.92619	testBot	1042	\N
13985	{"message":"Job (id=1042) execution started","level":2}	2019-12-07 09:29:41.980747	testBot	1042	\N
13986	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:41.982748	testBot	1042	\N
13987	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:41.992076	testBot	1042	\N
13988	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:41.994058	testBot	1042	\N
13989	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:42.00229	testBot	1042	\N
13990	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:42.004882	testBot	1042	\N
13991	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:42.009272	testBot	1042	\N
13992	{"message":"Job (id=1042) failed'","level":0}	2019-12-07 09:29:42.014702	testBot	1042	\N
13993	{"message":"Job (id=1042) execution started","level":2}	2019-12-07 09:29:42.068378	testBot	1042	\N
13994	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:42.070243	testBot	1042	\N
13995	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:42.079549	testBot	1042	\N
13996	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:42.081627	testBot	1042	\N
13997	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:42.090952	testBot	1042	\N
13998	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:42.093059	testBot	1042	\N
13999	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:42.095821	testBot	1042	\N
14000	{"message":"Job (id=1042) executed successfully","level":2}	2019-12-07 09:29:42.100716	testBot	1042	\N
14001	{"message":"Job (id=1042) execution started","level":2}	2019-12-07 09:29:42.149185	testBot	1042	\N
14002	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:42.151182	testBot	1042	\N
14003	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:42.160506	testBot	1042	\N
14004	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:42.162704	testBot	1042	\N
14005	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:42.171832	testBot	1042	\N
14006	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:42.174598	testBot	1042	\N
14007	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:42.177351	testBot	1042	\N
14008	{"message":"Job (id=1042) executed successfully","level":2}	2019-12-07 09:29:42.181739	testBot	1042	\N
14009	{"message":"Job (id=1042) execution started","level":2}	2019-12-07 09:29:42.230682	testBot	1042	\N
14010	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:42.232713	testBot	1042	\N
14011	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:42.242575	testBot	1042	\N
14012	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:42.244697	testBot	1042	\N
14013	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:42.254015	testBot	1042	\N
14014	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:42.256459	testBot	1042	\N
14015	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:29:42.259182	testBot	1042	\N
14016	{"message":"Job (id=1042) executed successfully","level":2}	2019-12-07 09:29:42.263671	testBot	1042	\N
14017	{"message":"Job (id=1042) execution started","level":2}	2019-12-07 09:29:42.305972	testBot	1042	\N
14018	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:42.307968	testBot	1042	\N
14019	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:42.317569	testBot	1042	\N
14020	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:42.319585	testBot	1042	\N
14021	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:42.327622	testBot	1042	\N
14022	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:42.330587	testBot	1042	\N
14023	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:29:42.333394	testBot	1042	\N
14024	{"message":"Job (id=1042) executed successfully","level":2}	2019-12-07 09:29:42.338383	testBot	1042	\N
14025	{"message":"Job (id=1042) execution started","level":2}	2019-12-07 09:29:42.383738	testBot	1042	\N
14026	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:29:42.386028	testBot	1042	\N
14027	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:29:42.394414	testBot	1042	\N
14028	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:29:42.396222	testBot	1042	\N
14029	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:29:42.404709	testBot	1042	\N
14030	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:29:42.406828	testBot	1042	\N
14031	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:29:42.40905	testBot	1042	\N
14032	{"message":"Job (id=1042) failed'","level":0}	2019-12-07 09:29:42.414049	testBot	1042	\N
14033	{"message":"Job (id=1042) execution started","level":2}	2019-12-07 09:29:42.457879	testBot	1042	\N
14034	{"message":"No any steps were found for job (id=1042)","level":0}	2019-12-07 09:29:42.460444	testBot	1042	\N
14035	{"message":"Job (id=1042) executed successfully","level":2}	2019-12-07 09:29:42.465122	testBot	1042	\N
14036	{"message":"Job (id=1044) execution started","level":2}	2019-12-07 09:31:16.695105	testBot	1044	\N
14037	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:16.700385	testBot	1044	\N
14038	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:16.713036	testBot	1044	\N
14039	{"message":"Job (id=1044) executed successfully","level":2}	2019-12-07 09:31:16.720148	testBot	1044	\N
14040	{"message":"Job (id=1044) execution started","level":2}	2019-12-07 09:31:16.799866	testBot	1044	\N
14041	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:16.802182	testBot	1044	\N
14042	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:16.814008	testBot	1044	\N
14043	{"message":"Job (id=1044) failed'","level":0}	2019-12-07 09:31:16.819668	testBot	1044	\N
14044	{"message":"Job (id=1044) execution started","level":2}	2019-12-07 09:31:16.870805	testBot	1044	\N
14045	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:16.873041	testBot	1044	\N
14046	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:16.88281	testBot	1044	\N
14047	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:16.88512	testBot	1044	\N
14048	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:16.892238	testBot	1044	\N
14049	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:16.89434	testBot	1044	\N
14050	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:16.89741	testBot	1044	\N
14051	{"message":"Job (id=1044) failed'","level":0}	2019-12-07 09:31:16.901564	testBot	1044	\N
14052	{"message":"Job (id=1044) execution started","level":2}	2019-12-07 09:31:16.955766	testBot	1044	\N
14053	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:16.957575	testBot	1044	\N
14054	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:16.967028	testBot	1044	\N
14055	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:16.969097	testBot	1044	\N
14056	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:16.978157	testBot	1044	\N
14057	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:16.980733	testBot	1044	\N
14058	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:16.983481	testBot	1044	\N
14059	{"message":"Job (id=1044) executed successfully","level":2}	2019-12-07 09:31:16.988566	testBot	1044	\N
14060	{"message":"Job (id=1044) execution started","level":2}	2019-12-07 09:31:17.04103	testBot	1044	\N
14061	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:17.042961	testBot	1044	\N
14062	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:17.051567	testBot	1044	\N
14063	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:17.053892	testBot	1044	\N
14064	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:17.06213	testBot	1044	\N
14065	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:17.064787	testBot	1044	\N
14066	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:17.067482	testBot	1044	\N
14067	{"message":"Job (id=1044) executed successfully","level":2}	2019-12-07 09:31:17.073182	testBot	1044	\N
14068	{"message":"Job (id=1044) execution started","level":2}	2019-12-07 09:31:17.116158	testBot	1044	\N
14069	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:17.118153	testBot	1044	\N
14070	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:17.127721	testBot	1044	\N
14071	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:17.12989	testBot	1044	\N
14072	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:17.138417	testBot	1044	\N
14073	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:17.140992	testBot	1044	\N
14074	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:31:17.143876	testBot	1044	\N
14075	{"message":"Job (id=1044) executed successfully","level":2}	2019-12-07 09:31:17.148726	testBot	1044	\N
14076	{"message":"Job (id=1044) execution started","level":2}	2019-12-07 09:31:17.194804	testBot	1044	\N
14077	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:17.196968	testBot	1044	\N
14078	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:17.20522	testBot	1044	\N
14079	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:17.207212	testBot	1044	\N
14080	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:17.216337	testBot	1044	\N
14081	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:17.226317	testBot	1044	\N
14082	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:31:17.22882	testBot	1044	\N
14083	{"message":"Job (id=1044) executed successfully","level":2}	2019-12-07 09:31:17.234418	testBot	1044	\N
14084	{"message":"Job (id=1044) execution started","level":2}	2019-12-07 09:31:17.279936	testBot	1044	\N
14085	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:17.281778	testBot	1044	\N
14086	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:17.291571	testBot	1044	\N
14087	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:17.293655	testBot	1044	\N
14088	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:17.301882	testBot	1044	\N
14089	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:17.304375	testBot	1044	\N
14090	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:31:17.306819	testBot	1044	\N
14091	{"message":"Job (id=1044) failed'","level":0}	2019-12-07 09:31:17.312558	testBot	1044	\N
14092	{"message":"Job (id=1044) execution started","level":2}	2019-12-07 09:31:17.360232	testBot	1044	\N
14093	{"message":"No any steps were found for job (id=1044)","level":0}	2019-12-07 09:31:17.362611	testBot	1044	\N
14094	{"message":"Job (id=1044) executed successfully","level":2}	2019-12-07 09:31:17.366151	testBot	1044	\N
14095	{"message":"Job (id=1046) execution started","level":2}	2019-12-07 09:31:30.524606	testBot	1046	\N
14096	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:30.53022	testBot	1046	\N
14097	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:30.544481	testBot	1046	\N
14098	{"message":"Job (id=1046) executed successfully","level":2}	2019-12-07 09:31:30.554434	testBot	1046	\N
14099	{"message":"Job (id=1046) execution started","level":2}	2019-12-07 09:31:30.630631	testBot	1046	\N
14100	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:30.633511	testBot	1046	\N
14101	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:30.644575	testBot	1046	\N
14102	{"message":"Job (id=1046) failed'","level":0}	2019-12-07 09:31:30.649829	testBot	1046	\N
14103	{"message":"Job (id=1046) execution started","level":2}	2019-12-07 09:31:30.704821	testBot	1046	\N
14104	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:30.707618	testBot	1046	\N
14105	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:30.718091	testBot	1046	\N
14106	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:30.720985	testBot	1046	\N
14107	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:30.730515	testBot	1046	\N
14108	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:30.73312	testBot	1046	\N
14109	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:30.738897	testBot	1046	\N
14110	{"message":"Job (id=1046) failed'","level":0}	2019-12-07 09:31:30.74341	testBot	1046	\N
14111	{"message":"Job (id=1046) execution started","level":2}	2019-12-07 09:31:30.791931	testBot	1046	\N
14112	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:30.793778	testBot	1046	\N
14113	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:30.803141	testBot	1046	\N
14114	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:30.805426	testBot	1046	\N
14115	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:30.81493	testBot	1046	\N
14116	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:30.817536	testBot	1046	\N
14117	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:30.820184	testBot	1046	\N
14118	{"message":"Job (id=1046) executed successfully","level":2}	2019-12-07 09:31:30.824485	testBot	1046	\N
14119	{"message":"Job (id=1046) execution started","level":2}	2019-12-07 09:31:30.881107	testBot	1046	\N
14120	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:30.883545	testBot	1046	\N
14121	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:30.894882	testBot	1046	\N
14122	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:30.897679	testBot	1046	\N
14123	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:30.904297	testBot	1046	\N
14124	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:30.906844	testBot	1046	\N
14125	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:30.909336	testBot	1046	\N
14126	{"message":"Job (id=1046) executed successfully","level":2}	2019-12-07 09:31:30.914619	testBot	1046	\N
14127	{"message":"Job (id=1046) execution started","level":2}	2019-12-07 09:31:30.956662	testBot	1046	\N
14128	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:30.958689	testBot	1046	\N
14129	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:30.967843	testBot	1046	\N
14130	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:30.97008	testBot	1046	\N
14131	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:30.978535	testBot	1046	\N
14132	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:30.980812	testBot	1046	\N
14133	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:31:30.983062	testBot	1046	\N
14134	{"message":"Job (id=1046) executed successfully","level":2}	2019-12-07 09:31:30.987559	testBot	1046	\N
14135	{"message":"Job (id=1046) execution started","level":2}	2019-12-07 09:31:31.033373	testBot	1046	\N
14136	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:31.035529	testBot	1046	\N
14137	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:31.045437	testBot	1046	\N
14138	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:31.047643	testBot	1046	\N
14139	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:31.055732	testBot	1046	\N
14140	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:31.058204	testBot	1046	\N
14141	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:31:31.060431	testBot	1046	\N
14142	{"message":"Job (id=1046) executed successfully","level":2}	2019-12-07 09:31:31.064801	testBot	1046	\N
14143	{"message":"Job (id=1046) execution started","level":2}	2019-12-07 09:31:31.105849	testBot	1046	\N
14144	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:31:31.107731	testBot	1046	\N
14145	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:31:31.122832	testBot	1046	\N
14146	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:31:31.125442	testBot	1046	\N
14147	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:31:31.142188	testBot	1046	\N
14148	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:31:31.144851	testBot	1046	\N
14149	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:31:31.147231	testBot	1046	\N
14150	{"message":"Job (id=1046) failed'","level":0}	2019-12-07 09:31:31.152107	testBot	1046	\N
14151	{"message":"Job (id=1046) execution started","level":2}	2019-12-07 09:31:31.194619	testBot	1046	\N
14152	{"message":"No any steps were found for job (id=1046)","level":0}	2019-12-07 09:31:31.197143	testBot	1046	\N
14153	{"message":"Job (id=1046) executed successfully","level":2}	2019-12-07 09:31:31.201228	testBot	1046	\N
14154	{"message":"Job (id=1048) execution started","level":2}	2019-12-07 09:33:00.575133	testBot	1048	\N
14155	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:00.57978	testBot	1048	\N
14156	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:00.591053	testBot	1048	\N
14157	{"message":"Job (id=1048) executed successfully","level":2}	2019-12-07 09:33:00.59752	testBot	1048	\N
14158	{"message":"Job (id=1048) execution started","level":2}	2019-12-07 09:33:00.676019	testBot	1048	\N
14159	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:00.677845	testBot	1048	\N
14160	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:00.686485	testBot	1048	\N
14161	{"message":"Job (id=1048) failed'","level":0}	2019-12-07 09:33:00.691534	testBot	1048	\N
14162	{"message":"Job (id=1048) execution started","level":2}	2019-12-07 09:33:00.747557	testBot	1048	\N
14163	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:00.749697	testBot	1048	\N
14164	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:00.759993	testBot	1048	\N
14165	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:00.762364	testBot	1048	\N
14166	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:00.772096	testBot	1048	\N
14167	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:00.779477	testBot	1048	\N
14168	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:00.783667	testBot	1048	\N
14169	{"message":"Job (id=1048) failed'","level":0}	2019-12-07 09:33:00.788222	testBot	1048	\N
14170	{"message":"Job (id=1048) execution started","level":2}	2019-12-07 09:33:00.835855	testBot	1048	\N
14171	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:00.83805	testBot	1048	\N
14172	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:00.846733	testBot	1048	\N
14173	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:00.84901	testBot	1048	\N
14174	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:00.856694	testBot	1048	\N
14175	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:00.858796	testBot	1048	\N
14176	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:00.860953	testBot	1048	\N
14177	{"message":"Job (id=1048) executed successfully","level":2}	2019-12-07 09:33:00.865295	testBot	1048	\N
14178	{"message":"Job (id=1048) execution started","level":2}	2019-12-07 09:33:00.910782	testBot	1048	\N
14179	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:00.912812	testBot	1048	\N
14180	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:00.922462	testBot	1048	\N
14181	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:00.92461	testBot	1048	\N
14182	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:00.932537	testBot	1048	\N
14183	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:00.934785	testBot	1048	\N
14184	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:00.937722	testBot	1048	\N
14185	{"message":"Job (id=1048) executed successfully","level":2}	2019-12-07 09:33:00.942421	testBot	1048	\N
14186	{"message":"Job (id=1048) execution started","level":2}	2019-12-07 09:33:00.986194	testBot	1048	\N
14187	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:00.987985	testBot	1048	\N
14188	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:00.996448	testBot	1048	\N
14189	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:00.998865	testBot	1048	\N
14190	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:01.007184	testBot	1048	\N
14191	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:01.009381	testBot	1048	\N
14192	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:33:01.01156	testBot	1048	\N
14193	{"message":"Job (id=1048) executed successfully","level":2}	2019-12-07 09:33:01.01621	testBot	1048	\N
14194	{"message":"Job (id=1048) execution started","level":2}	2019-12-07 09:33:01.057907	testBot	1048	\N
14195	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:01.059696	testBot	1048	\N
14196	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:01.068365	testBot	1048	\N
14197	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:01.070363	testBot	1048	\N
14198	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:01.079236	testBot	1048	\N
14199	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:01.081841	testBot	1048	\N
14200	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:33:01.084808	testBot	1048	\N
14201	{"message":"Job (id=1048) executed successfully","level":2}	2019-12-07 09:33:01.090137	testBot	1048	\N
14202	{"message":"Job (id=1048) execution started","level":2}	2019-12-07 09:33:01.134417	testBot	1048	\N
14203	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:01.136514	testBot	1048	\N
14204	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:01.147288	testBot	1048	\N
14205	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:01.149372	testBot	1048	\N
14206	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:01.158262	testBot	1048	\N
14207	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:01.161341	testBot	1048	\N
14208	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:33:01.163929	testBot	1048	\N
14209	{"message":"Job (id=1048) failed'","level":0}	2019-12-07 09:33:01.168802	testBot	1048	\N
14210	{"message":"Job (id=1048) execution started","level":2}	2019-12-07 09:33:01.209173	testBot	1048	\N
14211	{"message":"No any steps were found for job (id=1048)","level":0}	2019-12-07 09:33:01.211694	testBot	1048	\N
14212	{"message":"Job (id=1048) executed successfully","level":2}	2019-12-07 09:33:01.215922	testBot	1048	\N
14213	{"message":"Job (id=1050) execution started","level":2}	2019-12-07 09:33:27.342538	testBot	1050	\N
14214	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:27.345994	testBot	1050	\N
14215	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:27.357108	testBot	1050	\N
14216	{"message":"Job (id=1050) executed successfully","level":2}	2019-12-07 09:33:27.363135	testBot	1050	\N
14217	{"message":"Job (id=1050) execution started","level":2}	2019-12-07 09:33:27.440665	testBot	1050	\N
14218	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:27.442443	testBot	1050	\N
14219	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:27.451707	testBot	1050	\N
14220	{"message":"Job (id=1050) failed'","level":0}	2019-12-07 09:33:27.455918	testBot	1050	\N
14221	{"message":"Job (id=1050) execution started","level":2}	2019-12-07 09:33:27.504318	testBot	1050	\N
14222	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:27.506216	testBot	1050	\N
14223	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:27.515958	testBot	1050	\N
14224	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:27.517847	testBot	1050	\N
14225	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:27.526504	testBot	1050	\N
14226	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:27.528715	testBot	1050	\N
14227	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:27.5325	testBot	1050	\N
14228	{"message":"Job (id=1050) failed'","level":0}	2019-12-07 09:33:27.53677	testBot	1050	\N
14229	{"message":"Job (id=1050) execution started","level":2}	2019-12-07 09:33:27.581407	testBot	1050	\N
14230	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:27.583281	testBot	1050	\N
14231	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:27.591832	testBot	1050	\N
14232	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:27.594168	testBot	1050	\N
14233	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:27.603057	testBot	1050	\N
14234	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:27.605409	testBot	1050	\N
14235	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:27.607889	testBot	1050	\N
14236	{"message":"Job (id=1050) executed successfully","level":2}	2019-12-07 09:33:27.612675	testBot	1050	\N
14237	{"message":"Job (id=1050) execution started","level":2}	2019-12-07 09:33:27.659726	testBot	1050	\N
14238	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:27.661528	testBot	1050	\N
14239	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:27.670814	testBot	1050	\N
14240	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:27.672746	testBot	1050	\N
14241	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:27.680864	testBot	1050	\N
14242	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:27.683045	testBot	1050	\N
14243	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:27.68516	testBot	1050	\N
14244	{"message":"Job (id=1050) executed successfully","level":2}	2019-12-07 09:33:27.689985	testBot	1050	\N
14245	{"message":"Job (id=1050) execution started","level":2}	2019-12-07 09:33:27.736811	testBot	1050	\N
14246	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:27.738634	testBot	1050	\N
14247	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:27.747401	testBot	1050	\N
14248	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:27.749531	testBot	1050	\N
14249	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:27.758698	testBot	1050	\N
14250	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:27.76089	testBot	1050	\N
14251	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:33:27.763299	testBot	1050	\N
14252	{"message":"Job (id=1050) executed successfully","level":2}	2019-12-07 09:33:27.773839	testBot	1050	\N
14253	{"message":"Job (id=1050) execution started","level":2}	2019-12-07 09:33:27.816264	testBot	1050	\N
14254	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:27.818151	testBot	1050	\N
14255	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:27.827429	testBot	1050	\N
14256	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:27.829302	testBot	1050	\N
14257	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:27.837833	testBot	1050	\N
14258	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:27.839874	testBot	1050	\N
14259	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:33:27.84224	testBot	1050	\N
14260	{"message":"Job (id=1050) executed successfully","level":2}	2019-12-07 09:33:27.846726	testBot	1050	\N
14261	{"message":"Job (id=1050) execution started","level":2}	2019-12-07 09:33:27.886575	testBot	1050	\N
14262	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:33:27.888402	testBot	1050	\N
14263	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:33:27.897418	testBot	1050	\N
14264	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:33:27.899755	testBot	1050	\N
14265	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:33:27.908266	testBot	1050	\N
14266	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:33:27.91037	testBot	1050	\N
14267	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:33:27.912489	testBot	1050	\N
14268	{"message":"Job (id=1050) failed'","level":0}	2019-12-07 09:33:27.916797	testBot	1050	\N
14269	{"message":"Job (id=1050) execution started","level":2}	2019-12-07 09:33:27.958597	testBot	1050	\N
14270	{"message":"No any steps were found for job (id=1050)","level":0}	2019-12-07 09:33:27.961624	testBot	1050	\N
14271	{"message":"Job (id=1050) executed successfully","level":2}	2019-12-07 09:33:27.965342	testBot	1050	\N
14272	{"message":"Job (id=1052) execution started","level":2}	2019-12-07 09:34:26.053982	testBot	1052	\N
14273	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:34:26.060554	testBot	1052	\N
14274	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:34:26.074143	testBot	1052	\N
14275	{"message":"Job (id=1052) executed successfully","level":2}	2019-12-07 09:34:26.080991	testBot	1052	\N
14276	{"message":"Job (id=1052) execution started","level":2}	2019-12-07 09:34:26.160066	testBot	1052	\N
14277	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:34:26.161874	testBot	1052	\N
14278	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:34:26.172081	testBot	1052	\N
14279	{"message":"Job (id=1052) failed'","level":0}	2019-12-07 09:34:26.176483	testBot	1052	\N
14280	{"message":"Job (id=1052) execution started","level":2}	2019-12-07 09:34:26.229037	testBot	1052	\N
14281	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:34:26.230764	testBot	1052	\N
14282	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:34:26.239056	testBot	1052	\N
14283	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:34:26.241043	testBot	1052	\N
14284	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:34:26.248902	testBot	1052	\N
14285	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:34:26.251538	testBot	1052	\N
14286	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:34:26.254769	testBot	1052	\N
14287	{"message":"Job (id=1052) failed'","level":0}	2019-12-07 09:34:26.259781	testBot	1052	\N
14288	{"message":"Job (id=1052) execution started","level":2}	2019-12-07 09:34:26.311254	testBot	1052	\N
14289	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:34:26.313358	testBot	1052	\N
14290	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:34:26.322217	testBot	1052	\N
14291	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:34:26.329906	testBot	1052	\N
14292	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:34:26.338145	testBot	1052	\N
14293	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:34:26.340306	testBot	1052	\N
14294	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:34:26.343135	testBot	1052	\N
14295	{"message":"Job (id=1052) executed successfully","level":2}	2019-12-07 09:34:26.3481	testBot	1052	\N
14296	{"message":"Job (id=1052) execution started","level":2}	2019-12-07 09:34:26.402201	testBot	1052	\N
14297	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:34:26.404329	testBot	1052	\N
14298	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:34:26.412894	testBot	1052	\N
14299	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:34:26.414701	testBot	1052	\N
14300	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:34:26.42202	testBot	1052	\N
14301	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:34:26.42396	testBot	1052	\N
14302	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:34:26.426049	testBot	1052	\N
14303	{"message":"Job (id=1052) executed successfully","level":2}	2019-12-07 09:34:26.43086	testBot	1052	\N
14304	{"message":"Job (id=1052) execution started","level":2}	2019-12-07 09:34:26.489991	testBot	1052	\N
14305	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:34:26.49189	testBot	1052	\N
14306	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:34:26.501394	testBot	1052	\N
14307	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:34:26.504621	testBot	1052	\N
14308	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:34:26.512859	testBot	1052	\N
14309	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:34:26.515326	testBot	1052	\N
14310	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:34:26.517794	testBot	1052	\N
14311	{"message":"Job (id=1052) executed successfully","level":2}	2019-12-07 09:34:26.523052	testBot	1052	\N
14312	{"message":"Job (id=1052) execution started","level":2}	2019-12-07 09:34:26.572322	testBot	1052	\N
14313	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:34:26.574841	testBot	1052	\N
14314	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:34:26.584196	testBot	1052	\N
14315	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:34:26.58653	testBot	1052	\N
14316	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:34:26.593937	testBot	1052	\N
14317	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:34:26.595982	testBot	1052	\N
14318	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:34:26.598331	testBot	1052	\N
14319	{"message":"Job (id=1052) executed successfully","level":2}	2019-12-07 09:34:26.602931	testBot	1052	\N
14320	{"message":"Job (id=1052) execution started","level":2}	2019-12-07 09:34:26.646418	testBot	1052	\N
14321	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:34:26.648357	testBot	1052	\N
14322	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:34:26.656221	testBot	1052	\N
14323	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:34:26.658167	testBot	1052	\N
14324	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:34:26.666642	testBot	1052	\N
14325	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:34:26.668876	testBot	1052	\N
14326	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:34:26.671481	testBot	1052	\N
14327	{"message":"Job (id=1052) failed'","level":0}	2019-12-07 09:34:26.675148	testBot	1052	\N
14328	{"message":"Job (id=1052) execution started","level":2}	2019-12-07 09:34:26.721519	testBot	1052	\N
14329	{"message":"No any steps were found for job (id=1052)","level":0}	2019-12-07 09:34:26.724938	testBot	1052	\N
14330	{"message":"Job (id=1052) executed successfully","level":2}	2019-12-07 09:34:26.729598	testBot	1052	\N
14331	{"message":"Job (id=1054) execution started","level":2}	2019-12-07 09:35:02.921634	testBot	1054	\N
14332	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:35:02.927262	testBot	1054	\N
14333	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:35:02.939236	testBot	1054	\N
14334	{"message":"Job (id=1054) executed successfully","level":2}	2019-12-07 09:35:02.946427	testBot	1054	\N
14335	{"message":"Job (id=1054) execution started","level":2}	2019-12-07 09:35:03.023844	testBot	1054	\N
14336	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:35:03.025792	testBot	1054	\N
14337	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:35:03.035169	testBot	1054	\N
14338	{"message":"Job (id=1054) failed'","level":0}	2019-12-07 09:35:03.039995	testBot	1054	\N
14339	{"message":"Job (id=1054) execution started","level":2}	2019-12-07 09:35:03.087471	testBot	1054	\N
14340	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:35:03.08969	testBot	1054	\N
14341	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:35:03.10853	testBot	1054	\N
14342	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:35:03.111299	testBot	1054	\N
14343	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:35:03.121788	testBot	1054	\N
14344	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:35:03.12438	testBot	1054	\N
14345	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:35:03.129519	testBot	1054	\N
14346	{"message":"Job (id=1054) failed'","level":0}	2019-12-07 09:35:03.13521	testBot	1054	\N
14347	{"message":"Job (id=1054) execution started","level":2}	2019-12-07 09:35:03.182481	testBot	1054	\N
14348	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:35:03.185103	testBot	1054	\N
14349	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:35:03.195088	testBot	1054	\N
14350	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:35:03.197461	testBot	1054	\N
14351	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:35:03.206735	testBot	1054	\N
14352	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:35:03.20912	testBot	1054	\N
14353	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:35:03.21165	testBot	1054	\N
14354	{"message":"Job (id=1054) executed successfully","level":2}	2019-12-07 09:35:03.216707	testBot	1054	\N
14355	{"message":"Job (id=1054) execution started","level":2}	2019-12-07 09:35:03.264412	testBot	1054	\N
14356	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:35:03.266313	testBot	1054	\N
14357	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:35:03.273932	testBot	1054	\N
14358	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:35:03.27667	testBot	1054	\N
14359	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:35:03.283084	testBot	1054	\N
14360	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:35:03.2854	testBot	1054	\N
14361	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:35:03.287341	testBot	1054	\N
14362	{"message":"Job (id=1054) executed successfully","level":2}	2019-12-07 09:35:03.296878	testBot	1054	\N
14363	{"message":"Job (id=1054) execution started","level":2}	2019-12-07 09:35:03.339089	testBot	1054	\N
14364	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:35:03.340859	testBot	1054	\N
14365	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:35:03.350027	testBot	1054	\N
14366	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:35:03.351964	testBot	1054	\N
14367	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:35:03.359877	testBot	1054	\N
14368	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:35:03.362445	testBot	1054	\N
14369	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:35:03.365315	testBot	1054	\N
14370	{"message":"Job (id=1054) executed successfully","level":2}	2019-12-07 09:35:03.369603	testBot	1054	\N
14371	{"message":"Job (id=1054) execution started","level":2}	2019-12-07 09:35:03.412839	testBot	1054	\N
14372	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:35:03.41493	testBot	1054	\N
14373	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:35:03.424648	testBot	1054	\N
14374	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:35:03.42681	testBot	1054	\N
14375	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:35:03.43527	testBot	1054	\N
14376	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:35:03.437442	testBot	1054	\N
14377	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:35:03.439606	testBot	1054	\N
14378	{"message":"Job (id=1054) executed successfully","level":2}	2019-12-07 09:35:03.444168	testBot	1054	\N
14379	{"message":"Job (id=1054) execution started","level":2}	2019-12-07 09:35:03.488434	testBot	1054	\N
14380	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:35:03.490163	testBot	1054	\N
14381	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:35:03.499406	testBot	1054	\N
14382	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:35:03.501624	testBot	1054	\N
14383	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:35:03.510088	testBot	1054	\N
14384	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:35:03.512312	testBot	1054	\N
14385	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:35:03.514524	testBot	1054	\N
14386	{"message":"Job (id=1054) failed'","level":0}	2019-12-07 09:35:03.519658	testBot	1054	\N
14387	{"message":"Job (id=1054) execution started","level":2}	2019-12-07 09:35:03.562206	testBot	1054	\N
14388	{"message":"No any steps were found for job (id=1054)","level":0}	2019-12-07 09:35:03.564678	testBot	1054	\N
14389	{"message":"Job (id=1054) executed successfully","level":2}	2019-12-07 09:35:03.568494	testBot	1054	\N
14390	{"message":"Job (id=1056) execution started","level":2}	2019-12-07 09:36:49.669099	testBot	1056	\N
14391	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:36:49.677226	testBot	1056	\N
14392	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:36:49.690419	testBot	1056	\N
14393	{"message":"Job (id=1056) executed successfully","level":2}	2019-12-07 09:36:49.698576	testBot	1056	\N
14394	{"message":"Job (id=1056) execution started","level":2}	2019-12-07 09:36:49.778014	testBot	1056	\N
14395	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:36:49.780501	testBot	1056	\N
14396	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:36:49.791187	testBot	1056	\N
14397	{"message":"Job (id=1056) failed'","level":0}	2019-12-07 09:36:49.79669	testBot	1056	\N
14398	{"message":"Job (id=1056) execution started","level":2}	2019-12-07 09:36:49.858074	testBot	1056	\N
14399	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:36:49.860433	testBot	1056	\N
14400	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:36:49.870825	testBot	1056	\N
14401	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:36:49.873095	testBot	1056	\N
14402	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:36:49.883084	testBot	1056	\N
14403	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:36:49.886083	testBot	1056	\N
14404	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:36:49.890973	testBot	1056	\N
14405	{"message":"Job (id=1056) failed'","level":0}	2019-12-07 09:36:49.896066	testBot	1056	\N
14406	{"message":"Job (id=1056) execution started","level":2}	2019-12-07 09:36:49.940652	testBot	1056	\N
14407	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:36:49.942599	testBot	1056	\N
14408	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:36:49.959751	testBot	1056	\N
14409	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:36:49.962316	testBot	1056	\N
14410	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:36:49.971522	testBot	1056	\N
14411	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:36:49.974316	testBot	1056	\N
14412	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:36:49.977033	testBot	1056	\N
14413	{"message":"Job (id=1056) executed successfully","level":2}	2019-12-07 09:36:49.982147	testBot	1056	\N
14414	{"message":"Job (id=1056) execution started","level":2}	2019-12-07 09:36:50.033632	testBot	1056	\N
14415	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:36:50.035913	testBot	1056	\N
14416	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:36:50.045551	testBot	1056	\N
14417	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:36:50.047681	testBot	1056	\N
14418	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:36:50.057254	testBot	1056	\N
14419	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:36:50.059762	testBot	1056	\N
14420	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:36:50.062368	testBot	1056	\N
14421	{"message":"Job (id=1056) executed successfully","level":2}	2019-12-07 09:36:50.073225	testBot	1056	\N
14422	{"message":"Job (id=1056) execution started","level":2}	2019-12-07 09:36:50.119392	testBot	1056	\N
14423	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:36:50.121857	testBot	1056	\N
14424	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:36:50.131143	testBot	1056	\N
14425	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:36:50.133329	testBot	1056	\N
14426	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:36:50.142388	testBot	1056	\N
14427	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:36:50.144751	testBot	1056	\N
14428	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:36:50.147338	testBot	1056	\N
14429	{"message":"Job (id=1056) executed successfully","level":2}	2019-12-07 09:36:50.152173	testBot	1056	\N
14430	{"message":"Job (id=1056) execution started","level":2}	2019-12-07 09:36:50.195957	testBot	1056	\N
14431	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:36:50.198594	testBot	1056	\N
14432	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:36:50.212966	testBot	1056	\N
14433	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:36:50.215036	testBot	1056	\N
14434	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:36:50.223596	testBot	1056	\N
14435	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:36:50.225879	testBot	1056	\N
14436	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:36:50.228185	testBot	1056	\N
14437	{"message":"Job (id=1056) executed successfully","level":2}	2019-12-07 09:36:50.232969	testBot	1056	\N
14438	{"message":"Job (id=1056) execution started","level":2}	2019-12-07 09:36:50.27587	testBot	1056	\N
14439	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:36:50.277904	testBot	1056	\N
14440	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:36:50.287075	testBot	1056	\N
14441	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:36:50.289139	testBot	1056	\N
14442	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:36:50.297722	testBot	1056	\N
14443	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:36:50.300149	testBot	1056	\N
14444	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:36:50.302651	testBot	1056	\N
14445	{"message":"Job (id=1056) failed'","level":0}	2019-12-07 09:36:50.307733	testBot	1056	\N
14446	{"message":"Job (id=1056) execution started","level":2}	2019-12-07 09:36:50.34807	testBot	1056	\N
14447	{"message":"No any steps were found for job (id=1056)","level":0}	2019-12-07 09:36:50.350745	testBot	1056	\N
14448	{"message":"Job (id=1056) executed successfully","level":2}	2019-12-07 09:36:50.354572	testBot	1056	\N
14449	{"message":"Job (id=1058) execution started","level":2}	2019-12-07 09:38:03.918069	testBot	1058	\N
14450	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:38:03.926193	testBot	1058	\N
14451	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:38:03.937962	testBot	1058	\N
14452	{"message":"Job (id=1058) executed successfully","level":2}	2019-12-07 09:38:03.94452	testBot	1058	\N
14453	{"message":"Job (id=1058) execution started","level":2}	2019-12-07 09:38:04.045984	testBot	1058	\N
14454	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:38:04.04849	testBot	1058	\N
14455	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:38:04.057952	testBot	1058	\N
14456	{"message":"Job (id=1058) failed'","level":0}	2019-12-07 09:38:04.062351	testBot	1058	\N
14457	{"message":"Job (id=1058) execution started","level":2}	2019-12-07 09:38:04.118792	testBot	1058	\N
14458	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:38:04.121482	testBot	1058	\N
14459	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:38:04.131589	testBot	1058	\N
14460	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:38:04.133966	testBot	1058	\N
14461	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:38:04.142886	testBot	1058	\N
14462	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:38:04.145247	testBot	1058	\N
14463	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:38:04.149093	testBot	1058	\N
14464	{"message":"Job (id=1058) failed'","level":0}	2019-12-07 09:38:04.153876	testBot	1058	\N
14465	{"message":"Job (id=1058) execution started","level":2}	2019-12-07 09:38:04.200878	testBot	1058	\N
14466	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:38:04.203396	testBot	1058	\N
14467	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:38:04.213844	testBot	1058	\N
14468	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:38:04.216087	testBot	1058	\N
14469	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:38:04.225722	testBot	1058	\N
14470	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:38:04.228175	testBot	1058	\N
14471	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:38:04.231044	testBot	1058	\N
14472	{"message":"Job (id=1058) executed successfully","level":2}	2019-12-07 09:38:04.237949	testBot	1058	\N
14473	{"message":"Job (id=1058) execution started","level":2}	2019-12-07 09:38:04.285107	testBot	1058	\N
14474	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:38:04.287518	testBot	1058	\N
14475	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:38:04.296254	testBot	1058	\N
14476	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:38:04.298318	testBot	1058	\N
14477	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:38:04.307146	testBot	1058	\N
14478	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:38:04.309566	testBot	1058	\N
14479	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:38:04.311986	testBot	1058	\N
14480	{"message":"Job (id=1058) executed successfully","level":2}	2019-12-07 09:38:04.316975	testBot	1058	\N
14481	{"message":"Job (id=1058) execution started","level":2}	2019-12-07 09:38:04.37011	testBot	1058	\N
14482	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:38:04.372713	testBot	1058	\N
14483	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:38:04.384352	testBot	1058	\N
14484	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:38:04.386579	testBot	1058	\N
14485	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:38:04.39569	testBot	1058	\N
14486	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:38:04.397692	testBot	1058	\N
14487	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:38:04.400119	testBot	1058	\N
14488	{"message":"Job (id=1058) executed successfully","level":2}	2019-12-07 09:38:04.409196	testBot	1058	\N
14489	{"message":"Job (id=1058) execution started","level":2}	2019-12-07 09:38:04.452262	testBot	1058	\N
14490	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:38:04.454657	testBot	1058	\N
14491	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:38:04.465022	testBot	1058	\N
14492	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:38:04.467623	testBot	1058	\N
14493	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:38:04.478689	testBot	1058	\N
14494	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:38:04.481005	testBot	1058	\N
14495	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:38:04.483324	testBot	1058	\N
14496	{"message":"Job (id=1058) executed successfully","level":2}	2019-12-07 09:38:04.488026	testBot	1058	\N
14497	{"message":"Job (id=1058) execution started","level":2}	2019-12-07 09:38:04.52944	testBot	1058	\N
14498	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:38:04.531485	testBot	1058	\N
14499	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:38:04.540222	testBot	1058	\N
14500	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:38:04.547754	testBot	1058	\N
14501	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:38:04.556239	testBot	1058	\N
14502	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:38:04.558771	testBot	1058	\N
14503	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:38:04.560829	testBot	1058	\N
14504	{"message":"Job (id=1058) failed'","level":0}	2019-12-07 09:38:04.56512	testBot	1058	\N
14505	{"message":"Job (id=1058) execution started","level":2}	2019-12-07 09:38:04.605981	testBot	1058	\N
14506	{"message":"No any steps were found for job (id=1058)","level":0}	2019-12-07 09:38:04.608675	testBot	1058	\N
14507	{"message":"Job (id=1058) executed successfully","level":2}	2019-12-07 09:38:04.612697	testBot	1058	\N
14508	{"message":"Job (id=1060) execution started","level":2}	2019-12-07 09:39:02.728045	testBot	1060	\N
14509	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:02.732372	testBot	1060	\N
14510	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:02.7446	testBot	1060	\N
14511	{"message":"Job (id=1060) executed successfully","level":2}	2019-12-07 09:39:02.752034	testBot	1060	\N
14512	{"message":"Job (id=1060) execution started","level":2}	2019-12-07 09:39:02.829083	testBot	1060	\N
14513	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:02.831304	testBot	1060	\N
14514	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:02.840762	testBot	1060	\N
14515	{"message":"Job (id=1060) failed'","level":0}	2019-12-07 09:39:02.845383	testBot	1060	\N
14516	{"message":"Job (id=1060) execution started","level":2}	2019-12-07 09:39:02.903553	testBot	1060	\N
14517	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:02.906136	testBot	1060	\N
14518	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:02.927336	testBot	1060	\N
14519	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:02.929813	testBot	1060	\N
14520	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:02.940042	testBot	1060	\N
14521	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:02.942918	testBot	1060	\N
14522	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:02.946876	testBot	1060	\N
14523	{"message":"Job (id=1060) failed'","level":0}	2019-12-07 09:39:02.952153	testBot	1060	\N
14524	{"message":"Job (id=1060) execution started","level":2}	2019-12-07 09:39:02.994281	testBot	1060	\N
14525	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:02.996029	testBot	1060	\N
14526	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:03.00472	testBot	1060	\N
14527	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:03.006625	testBot	1060	\N
14528	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:03.014939	testBot	1060	\N
14529	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:03.017099	testBot	1060	\N
14530	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:03.019206	testBot	1060	\N
14531	{"message":"Job (id=1060) executed successfully","level":2}	2019-12-07 09:39:03.024332	testBot	1060	\N
14532	{"message":"Job (id=1060) execution started","level":2}	2019-12-07 09:39:03.068624	testBot	1060	\N
14533	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:03.070744	testBot	1060	\N
14534	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:03.080471	testBot	1060	\N
14535	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:03.082586	testBot	1060	\N
14536	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:03.091696	testBot	1060	\N
14537	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:03.09402	testBot	1060	\N
14538	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:03.097616	testBot	1060	\N
14539	{"message":"Job (id=1060) executed successfully","level":2}	2019-12-07 09:39:03.102644	testBot	1060	\N
14540	{"message":"Job (id=1060) execution started","level":2}	2019-12-07 09:39:03.150095	testBot	1060	\N
14541	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:03.152096	testBot	1060	\N
14542	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:03.162471	testBot	1060	\N
14543	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:03.164865	testBot	1060	\N
14544	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:03.173787	testBot	1060	\N
14545	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:03.176293	testBot	1060	\N
14546	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:39:03.178608	testBot	1060	\N
14547	{"message":"Job (id=1060) executed successfully","level":2}	2019-12-07 09:39:03.183843	testBot	1060	\N
14548	{"message":"Job (id=1060) execution started","level":2}	2019-12-07 09:39:03.228668	testBot	1060	\N
14549	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:03.230787	testBot	1060	\N
14550	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:03.246295	testBot	1060	\N
14551	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:03.248537	testBot	1060	\N
14552	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:03.257588	testBot	1060	\N
14553	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:03.260382	testBot	1060	\N
14554	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:39:03.262621	testBot	1060	\N
14555	{"message":"Job (id=1060) executed successfully","level":2}	2019-12-07 09:39:03.267964	testBot	1060	\N
14556	{"message":"Job (id=1060) execution started","level":2}	2019-12-07 09:39:03.312129	testBot	1060	\N
14557	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:03.314146	testBot	1060	\N
14558	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:03.324662	testBot	1060	\N
14559	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:03.32673	testBot	1060	\N
14560	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:03.335486	testBot	1060	\N
14561	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:03.337975	testBot	1060	\N
14562	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:39:03.340522	testBot	1060	\N
14563	{"message":"Job (id=1060) failed'","level":0}	2019-12-07 09:39:03.345129	testBot	1060	\N
14564	{"message":"Job (id=1060) execution started","level":2}	2019-12-07 09:39:03.386952	testBot	1060	\N
14565	{"message":"No any steps were found for job (id=1060)","level":0}	2019-12-07 09:39:03.389342	testBot	1060	\N
14566	{"message":"Job (id=1060) executed successfully","level":2}	2019-12-07 09:39:03.393242	testBot	1060	\N
14567	{"message":"Job (id=1062) execution started","level":2}	2019-12-07 09:39:50.024974	testBot	1062	\N
14568	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:50.030275	testBot	1062	\N
14569	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:50.049941	testBot	1062	\N
14570	{"message":"Job (id=1062) executed successfully","level":2}	2019-12-07 09:39:50.058121	testBot	1062	\N
14571	{"message":"Job (id=1062) execution started","level":2}	2019-12-07 09:39:50.13513	testBot	1062	\N
14572	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:50.138186	testBot	1062	\N
14573	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:50.152527	testBot	1062	\N
14574	{"message":"Job (id=1062) failed'","level":0}	2019-12-07 09:39:50.158792	testBot	1062	\N
14575	{"message":"Job (id=1062) execution started","level":2}	2019-12-07 09:39:50.209953	testBot	1062	\N
14576	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:50.211892	testBot	1062	\N
14577	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:50.222055	testBot	1062	\N
14578	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:50.224175	testBot	1062	\N
14579	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:50.23404	testBot	1062	\N
14580	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:50.236491	testBot	1062	\N
14581	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:50.240599	testBot	1062	\N
14582	{"message":"Job (id=1062) failed'","level":0}	2019-12-07 09:39:50.245412	testBot	1062	\N
14583	{"message":"Job (id=1062) execution started","level":2}	2019-12-07 09:39:50.289901	testBot	1062	\N
14584	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:50.292134	testBot	1062	\N
14585	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:50.302493	testBot	1062	\N
14586	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:50.304489	testBot	1062	\N
14587	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:50.311723	testBot	1062	\N
14588	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:50.313827	testBot	1062	\N
14589	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:50.315837	testBot	1062	\N
14590	{"message":"Job (id=1062) executed successfully","level":2}	2019-12-07 09:39:50.320181	testBot	1062	\N
14591	{"message":"Job (id=1062) execution started","level":2}	2019-12-07 09:39:50.363309	testBot	1062	\N
14592	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:50.36512	testBot	1062	\N
14593	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:50.374188	testBot	1062	\N
14594	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:50.376294	testBot	1062	\N
14595	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:50.383975	testBot	1062	\N
14596	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:50.386672	testBot	1062	\N
14597	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:50.388805	testBot	1062	\N
14598	{"message":"Job (id=1062) executed successfully","level":2}	2019-12-07 09:39:50.393635	testBot	1062	\N
14599	{"message":"Job (id=1062) execution started","level":2}	2019-12-07 09:39:50.441219	testBot	1062	\N
14600	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:50.442938	testBot	1062	\N
14601	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:50.451988	testBot	1062	\N
14602	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:50.454086	testBot	1062	\N
14603	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:50.46259	testBot	1062	\N
14604	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:50.465858	testBot	1062	\N
14605	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:39:50.468439	testBot	1062	\N
14606	{"message":"Job (id=1062) executed successfully","level":2}	2019-12-07 09:39:50.473571	testBot	1062	\N
14607	{"message":"Job (id=1062) execution started","level":2}	2019-12-07 09:39:50.517382	testBot	1062	\N
14608	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:50.519208	testBot	1062	\N
14609	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:50.527949	testBot	1062	\N
14610	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:50.529937	testBot	1062	\N
14611	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:50.53803	testBot	1062	\N
14612	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:50.540266	testBot	1062	\N
14613	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:39:50.542426	testBot	1062	\N
14614	{"message":"Job (id=1062) executed successfully","level":2}	2019-12-07 09:39:50.546999	testBot	1062	\N
14615	{"message":"Job (id=1062) execution started","level":2}	2019-12-07 09:39:50.590334	testBot	1062	\N
14616	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:39:50.592326	testBot	1062	\N
14617	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:39:50.601998	testBot	1062	\N
14618	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:39:50.603935	testBot	1062	\N
14619	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:39:50.612589	testBot	1062	\N
14620	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:39:50.614866	testBot	1062	\N
14621	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:39:50.616963	testBot	1062	\N
14622	{"message":"Job (id=1062) failed'","level":0}	2019-12-07 09:39:50.621709	testBot	1062	\N
14623	{"message":"Job (id=1062) execution started","level":2}	2019-12-07 09:39:50.664894	testBot	1062	\N
14624	{"message":"No any steps were found for job (id=1062)","level":0}	2019-12-07 09:39:50.667864	testBot	1062	\N
14625	{"message":"Job (id=1062) executed successfully","level":2}	2019-12-07 09:39:50.676989	testBot	1062	\N
14626	{"message":"Job (id=1064) execution started","level":2}	2019-12-07 09:40:07.48441	testBot	1064	\N
14627	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:07.490532	testBot	1064	\N
14628	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:07.502944	testBot	1064	\N
14629	{"message":"Job (id=1064) executed successfully","level":2}	2019-12-07 09:40:07.50953	testBot	1064	\N
14630	{"message":"Job (id=1064) execution started","level":2}	2019-12-07 09:40:07.59709	testBot	1064	\N
14631	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:07.59944	testBot	1064	\N
14632	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:07.610041	testBot	1064	\N
14633	{"message":"Job (id=1064) failed'","level":0}	2019-12-07 09:40:07.615287	testBot	1064	\N
14634	{"message":"Job (id=1064) execution started","level":2}	2019-12-07 09:40:07.67014	testBot	1064	\N
14635	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:07.672367	testBot	1064	\N
14636	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:07.682182	testBot	1064	\N
14637	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:07.684392	testBot	1064	\N
14638	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:07.692036	testBot	1064	\N
14639	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:07.694385	testBot	1064	\N
14640	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:07.699108	testBot	1064	\N
14641	{"message":"Job (id=1064) failed'","level":0}	2019-12-07 09:40:07.710573	testBot	1064	\N
14642	{"message":"Job (id=1064) execution started","level":2}	2019-12-07 09:40:07.757255	testBot	1064	\N
14643	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:07.759567	testBot	1064	\N
14644	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:07.769118	testBot	1064	\N
14645	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:07.771895	testBot	1064	\N
14646	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:07.781552	testBot	1064	\N
14647	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:07.784351	testBot	1064	\N
14648	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:07.78709	testBot	1064	\N
14649	{"message":"Job (id=1064) executed successfully","level":2}	2019-12-07 09:40:07.792301	testBot	1064	\N
14650	{"message":"Job (id=1064) execution started","level":2}	2019-12-07 09:40:07.838033	testBot	1064	\N
14651	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:07.840107	testBot	1064	\N
14652	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:07.849922	testBot	1064	\N
14653	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:07.851805	testBot	1064	\N
14654	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:07.861232	testBot	1064	\N
14655	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:07.863509	testBot	1064	\N
14656	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:07.865569	testBot	1064	\N
14657	{"message":"Job (id=1064) executed successfully","level":2}	2019-12-07 09:40:07.870859	testBot	1064	\N
14658	{"message":"Job (id=1064) execution started","level":2}	2019-12-07 09:40:07.917924	testBot	1064	\N
14659	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:07.919972	testBot	1064	\N
14660	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:07.929412	testBot	1064	\N
14661	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:07.931635	testBot	1064	\N
14662	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:07.939642	testBot	1064	\N
14663	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:07.941742	testBot	1064	\N
14664	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:40:07.944097	testBot	1064	\N
14665	{"message":"Job (id=1064) executed successfully","level":2}	2019-12-07 09:40:07.948554	testBot	1064	\N
14666	{"message":"Job (id=1064) execution started","level":2}	2019-12-07 09:40:07.991852	testBot	1064	\N
14667	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:07.993557	testBot	1064	\N
14668	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:08.002012	testBot	1064	\N
14669	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:08.003731	testBot	1064	\N
14670	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:08.011015	testBot	1064	\N
14671	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:08.013735	testBot	1064	\N
14672	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:40:08.015791	testBot	1064	\N
14673	{"message":"Job (id=1064) executed successfully","level":2}	2019-12-07 09:40:08.019873	testBot	1064	\N
14674	{"message":"Job (id=1064) execution started","level":2}	2019-12-07 09:40:08.060645	testBot	1064	\N
14675	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:08.062266	testBot	1064	\N
14676	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:08.070403	testBot	1064	\N
14677	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:08.07214	testBot	1064	\N
14678	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:08.078786	testBot	1064	\N
14679	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:08.081151	testBot	1064	\N
14680	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:40:08.08889	testBot	1064	\N
14681	{"message":"Job (id=1064) failed'","level":0}	2019-12-07 09:40:08.093111	testBot	1064	\N
14682	{"message":"Job (id=1064) execution started","level":2}	2019-12-07 09:40:08.137196	testBot	1064	\N
14683	{"message":"No any steps were found for job (id=1064)","level":0}	2019-12-07 09:40:08.139686	testBot	1064	\N
14684	{"message":"Job (id=1064) executed successfully","level":2}	2019-12-07 09:40:08.143341	testBot	1064	\N
14685	{"message":"Job (id=1066) execution started","level":2}	2019-12-07 09:40:53.409134	testBot	1066	\N
14686	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:53.413158	testBot	1066	\N
14687	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:53.425561	testBot	1066	\N
14688	{"message":"Job (id=1066) executed successfully","level":2}	2019-12-07 09:40:53.433947	testBot	1066	\N
14689	{"message":"Job (id=1066) execution started","level":2}	2019-12-07 09:40:53.513115	testBot	1066	\N
14690	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:53.515704	testBot	1066	\N
14691	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:53.526336	testBot	1066	\N
14692	{"message":"Job (id=1066) failed'","level":0}	2019-12-07 09:40:53.53224	testBot	1066	\N
14693	{"message":"Job (id=1066) execution started","level":2}	2019-12-07 09:40:53.59384	testBot	1066	\N
14694	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:53.596214	testBot	1066	\N
14695	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:53.60504	testBot	1066	\N
14696	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:53.607024	testBot	1066	\N
14697	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:53.615379	testBot	1066	\N
14698	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:53.618209	testBot	1066	\N
14699	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:53.62324	testBot	1066	\N
14700	{"message":"Job (id=1066) failed'","level":0}	2019-12-07 09:40:53.627869	testBot	1066	\N
14701	{"message":"Job (id=1066) execution started","level":2}	2019-12-07 09:40:53.673331	testBot	1066	\N
14702	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:53.675444	testBot	1066	\N
14703	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:53.68475	testBot	1066	\N
14704	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:53.6867	testBot	1066	\N
14705	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:53.700574	testBot	1066	\N
14706	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:53.703637	testBot	1066	\N
14707	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:53.706777	testBot	1066	\N
14708	{"message":"Job (id=1066) executed successfully","level":2}	2019-12-07 09:40:53.71251	testBot	1066	\N
14709	{"message":"Job (id=1066) execution started","level":2}	2019-12-07 09:40:53.757379	testBot	1066	\N
14710	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:53.759656	testBot	1066	\N
14711	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:53.780713	testBot	1066	\N
14712	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:53.783367	testBot	1066	\N
14713	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:53.792045	testBot	1066	\N
14714	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:53.795082	testBot	1066	\N
14715	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:53.797461	testBot	1066	\N
14716	{"message":"Job (id=1066) executed successfully","level":2}	2019-12-07 09:40:53.803107	testBot	1066	\N
14717	{"message":"Job (id=1066) execution started","level":2}	2019-12-07 09:40:53.847025	testBot	1066	\N
14718	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:53.848732	testBot	1066	\N
14719	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:53.858337	testBot	1066	\N
14720	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:53.860314	testBot	1066	\N
14721	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:53.868547	testBot	1066	\N
14722	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:53.870717	testBot	1066	\N
14723	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:40:53.873128	testBot	1066	\N
14724	{"message":"Job (id=1066) executed successfully","level":2}	2019-12-07 09:40:53.877894	testBot	1066	\N
14725	{"message":"Job (id=1066) execution started","level":2}	2019-12-07 09:40:53.919257	testBot	1066	\N
14726	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:53.921905	testBot	1066	\N
14727	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:53.933	testBot	1066	\N
14728	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:53.934968	testBot	1066	\N
14729	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:53.942596	testBot	1066	\N
14730	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:53.944681	testBot	1066	\N
14731	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:40:53.946912	testBot	1066	\N
14732	{"message":"Job (id=1066) executed successfully","level":2}	2019-12-07 09:40:53.951571	testBot	1066	\N
14733	{"message":"Job (id=1066) execution started","level":2}	2019-12-07 09:40:53.994494	testBot	1066	\N
14734	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:40:53.99681	testBot	1066	\N
14735	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:40:54.005095	testBot	1066	\N
14736	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:40:54.006814	testBot	1066	\N
14737	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:40:54.012702	testBot	1066	\N
14738	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:40:54.015067	testBot	1066	\N
14739	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:40:54.022819	testBot	1066	\N
14740	{"message":"Job (id=1066) failed'","level":0}	2019-12-07 09:40:54.02672	testBot	1066	\N
14741	{"message":"Job (id=1066) execution started","level":2}	2019-12-07 09:40:54.069225	testBot	1066	\N
14742	{"message":"No any steps were found for job (id=1066)","level":0}	2019-12-07 09:40:54.071685	testBot	1066	\N
14743	{"message":"Job (id=1066) executed successfully","level":2}	2019-12-07 09:40:54.075485	testBot	1066	\N
14744	{"message":"Job (id=1068) execution started","level":2}	2019-12-07 09:42:04.016848	testBot	1068	\N
14745	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:42:04.023245	testBot	1068	\N
14746	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:42:04.037327	testBot	1068	\N
14747	{"message":"Job (id=1068) executed successfully","level":2}	2019-12-07 09:42:04.047448	testBot	1068	\N
14748	{"message":"Job (id=1068) execution started","level":2}	2019-12-07 09:42:04.129177	testBot	1068	\N
14749	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:42:04.131461	testBot	1068	\N
14750	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:42:04.141594	testBot	1068	\N
14751	{"message":"Job (id=1068) failed'","level":0}	2019-12-07 09:42:04.146454	testBot	1068	\N
14752	{"message":"Job (id=1068) execution started","level":2}	2019-12-07 09:42:04.207907	testBot	1068	\N
14753	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:42:04.210415	testBot	1068	\N
14754	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:42:04.221136	testBot	1068	\N
14755	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:42:04.223752	testBot	1068	\N
14756	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:42:04.233238	testBot	1068	\N
14757	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:42:04.23582	testBot	1068	\N
14758	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:42:04.241481	testBot	1068	\N
14759	{"message":"Job (id=1068) failed'","level":0}	2019-12-07 09:42:04.245685	testBot	1068	\N
14760	{"message":"Job (id=1068) execution started","level":2}	2019-12-07 09:42:04.289889	testBot	1068	\N
14761	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:42:04.292138	testBot	1068	\N
14762	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:42:04.302949	testBot	1068	\N
14763	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:42:04.305162	testBot	1068	\N
14764	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:42:04.313345	testBot	1068	\N
14765	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:42:04.31566	testBot	1068	\N
14766	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:42:04.318349	testBot	1068	\N
14767	{"message":"Job (id=1068) executed successfully","level":2}	2019-12-07 09:42:04.323307	testBot	1068	\N
14768	{"message":"Job (id=1068) execution started","level":2}	2019-12-07 09:42:04.365518	testBot	1068	\N
14769	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:42:04.367402	testBot	1068	\N
14770	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:42:04.376458	testBot	1068	\N
14771	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:42:04.378478	testBot	1068	\N
14772	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:42:04.387372	testBot	1068	\N
14773	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:42:04.389689	testBot	1068	\N
14774	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:42:04.392454	testBot	1068	\N
14775	{"message":"Job (id=1068) executed successfully","level":2}	2019-12-07 09:42:04.398045	testBot	1068	\N
14776	{"message":"Job (id=1068) execution started","level":2}	2019-12-07 09:42:04.44143	testBot	1068	\N
14777	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:42:04.443423	testBot	1068	\N
14778	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:42:04.452887	testBot	1068	\N
14779	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:42:04.455204	testBot	1068	\N
14780	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:42:04.464815	testBot	1068	\N
14781	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:42:04.467635	testBot	1068	\N
14782	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:42:04.47051	testBot	1068	\N
14783	{"message":"Job (id=1068) executed successfully","level":2}	2019-12-07 09:42:04.475708	testBot	1068	\N
14784	{"message":"Job (id=1068) execution started","level":2}	2019-12-07 09:42:04.518857	testBot	1068	\N
14785	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:42:04.521217	testBot	1068	\N
14786	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:42:04.531205	testBot	1068	\N
14787	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:42:04.533228	testBot	1068	\N
14788	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:42:04.543076	testBot	1068	\N
14789	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:42:04.545565	testBot	1068	\N
14790	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:42:04.548318	testBot	1068	\N
14791	{"message":"Job (id=1068) executed successfully","level":2}	2019-12-07 09:42:04.553081	testBot	1068	\N
14792	{"message":"Job (id=1068) execution started","level":2}	2019-12-07 09:42:04.591912	testBot	1068	\N
14793	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:42:04.593813	testBot	1068	\N
14794	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:42:04.604175	testBot	1068	\N
14795	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:42:04.606297	testBot	1068	\N
14796	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:42:04.615739	testBot	1068	\N
14797	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:42:04.617977	testBot	1068	\N
14798	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:42:04.620399	testBot	1068	\N
14799	{"message":"Job (id=1068) failed'","level":0}	2019-12-07 09:42:04.625115	testBot	1068	\N
14800	{"message":"Job (id=1068) execution started","level":2}	2019-12-07 09:42:04.666016	testBot	1068	\N
14801	{"message":"No any steps were found for job (id=1068)","level":0}	2019-12-07 09:42:04.668518	testBot	1068	\N
14802	{"message":"Job (id=1068) executed successfully","level":2}	2019-12-07 09:42:04.673122	testBot	1068	\N
14803	{"message":"Job (id=1070) execution started","level":2}	2019-12-07 09:43:22.573918	testBot	1070	\N
14804	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:43:22.582769	testBot	1070	\N
14805	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:43:22.596008	testBot	1070	\N
14806	{"message":"Job (id=1070) executed successfully","level":2}	2019-12-07 09:43:22.60247	testBot	1070	\N
14807	{"message":"Job (id=1070) execution started","level":2}	2019-12-07 09:43:22.677893	testBot	1070	\N
14808	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:43:22.680529	testBot	1070	\N
14809	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:43:22.690075	testBot	1070	\N
14810	{"message":"Job (id=1070) failed'","level":0}	2019-12-07 09:43:22.694253	testBot	1070	\N
14811	{"message":"Job (id=1070) execution started","level":2}	2019-12-07 09:43:22.747556	testBot	1070	\N
14812	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:43:22.749498	testBot	1070	\N
14813	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:43:22.759497	testBot	1070	\N
14814	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:43:22.761324	testBot	1070	\N
14815	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:43:22.7705	testBot	1070	\N
14816	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:43:22.777311	testBot	1070	\N
14817	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:43:22.781292	testBot	1070	\N
14818	{"message":"Job (id=1070) failed'","level":0}	2019-12-07 09:43:22.791506	testBot	1070	\N
14819	{"message":"Job (id=1070) execution started","level":2}	2019-12-07 09:43:22.836138	testBot	1070	\N
14820	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:43:22.838277	testBot	1070	\N
14821	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:43:22.847629	testBot	1070	\N
14822	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:43:22.850095	testBot	1070	\N
14823	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:43:22.858303	testBot	1070	\N
14824	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:43:22.860544	testBot	1070	\N
14825	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:43:22.862879	testBot	1070	\N
14826	{"message":"Job (id=1070) executed successfully","level":2}	2019-12-07 09:43:22.867003	testBot	1070	\N
14827	{"message":"Job (id=1070) execution started","level":2}	2019-12-07 09:43:22.909234	testBot	1070	\N
14828	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:43:22.911024	testBot	1070	\N
14829	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:43:22.920312	testBot	1070	\N
14830	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:43:22.922626	testBot	1070	\N
14831	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:43:22.931129	testBot	1070	\N
14832	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:43:22.933396	testBot	1070	\N
14833	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:43:22.93554	testBot	1070	\N
14834	{"message":"Job (id=1070) executed successfully","level":2}	2019-12-07 09:43:22.940052	testBot	1070	\N
14835	{"message":"Job (id=1070) execution started","level":2}	2019-12-07 09:43:22.986808	testBot	1070	\N
14836	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:43:22.988546	testBot	1070	\N
14837	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:43:22.99682	testBot	1070	\N
14838	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:43:22.998853	testBot	1070	\N
14839	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:43:23.006729	testBot	1070	\N
14840	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:43:23.008871	testBot	1070	\N
14841	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:43:23.011233	testBot	1070	\N
14842	{"message":"Job (id=1070) executed successfully","level":2}	2019-12-07 09:43:23.01539	testBot	1070	\N
14843	{"message":"Job (id=1070) execution started","level":2}	2019-12-07 09:43:23.055378	testBot	1070	\N
14844	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:43:23.057062	testBot	1070	\N
14845	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:43:23.066354	testBot	1070	\N
14846	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:43:23.068079	testBot	1070	\N
14847	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:43:23.075855	testBot	1070	\N
14848	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:43:23.078298	testBot	1070	\N
14849	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:43:23.080546	testBot	1070	\N
14850	{"message":"Job (id=1070) executed successfully","level":2}	2019-12-07 09:43:23.085233	testBot	1070	\N
14851	{"message":"Job (id=1070) execution started","level":2}	2019-12-07 09:43:23.125249	testBot	1070	\N
14852	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:43:23.126937	testBot	1070	\N
14853	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:43:23.135559	testBot	1070	\N
14854	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:43:23.13752	testBot	1070	\N
14855	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:43:23.145278	testBot	1070	\N
14856	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:43:23.147475	testBot	1070	\N
14857	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:43:23.149635	testBot	1070	\N
14858	{"message":"Job (id=1070) failed'","level":0}	2019-12-07 09:43:23.154268	testBot	1070	\N
14859	{"message":"Job (id=1070) execution started","level":2}	2019-12-07 09:43:23.195969	testBot	1070	\N
14860	{"message":"No any steps were found for job (id=1070)","level":0}	2019-12-07 09:43:23.198375	testBot	1070	\N
14861	{"message":"Job (id=1070) executed successfully","level":2}	2019-12-07 09:43:23.202034	testBot	1070	\N
14862	{"message":"Job (id=1072) execution started","level":2}	2019-12-07 09:46:30.705846	testBot	1072	\N
14863	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:46:30.712237	testBot	1072	\N
14864	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:46:30.724751	testBot	1072	\N
14865	{"message":"Job (id=1072) executed successfully","level":2}	2019-12-07 09:46:30.731408	testBot	1072	\N
14866	{"message":"Job (id=1072) execution started","level":2}	2019-12-07 09:46:30.806262	testBot	1072	\N
14867	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:46:30.808699	testBot	1072	\N
14868	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:46:30.819055	testBot	1072	\N
14869	{"message":"Job (id=1072) failed'","level":0}	2019-12-07 09:46:30.823806	testBot	1072	\N
14870	{"message":"Job (id=1072) execution started","level":2}	2019-12-07 09:46:30.874456	testBot	1072	\N
14871	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:46:30.876762	testBot	1072	\N
14872	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:46:30.88664	testBot	1072	\N
14873	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:46:30.888398	testBot	1072	\N
14874	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:46:30.8972	testBot	1072	\N
14875	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:46:30.900315	testBot	1072	\N
14876	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:46:30.904328	testBot	1072	\N
14877	{"message":"Job (id=1072) failed'","level":0}	2019-12-07 09:46:30.909315	testBot	1072	\N
14878	{"message":"Job (id=1072) execution started","level":2}	2019-12-07 09:46:30.952651	testBot	1072	\N
14879	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:46:30.954541	testBot	1072	\N
14880	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:46:30.963551	testBot	1072	\N
14881	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:46:30.965531	testBot	1072	\N
14882	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:46:30.973422	testBot	1072	\N
14883	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:46:30.9754	testBot	1072	\N
14884	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:46:30.977701	testBot	1072	\N
14885	{"message":"Job (id=1072) executed successfully","level":2}	2019-12-07 09:46:30.982101	testBot	1072	\N
14886	{"message":"Job (id=1072) execution started","level":2}	2019-12-07 09:46:31.030973	testBot	1072	\N
14887	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:46:31.033112	testBot	1072	\N
14888	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:46:31.043224	testBot	1072	\N
14889	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:46:31.045277	testBot	1072	\N
14890	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:46:31.053011	testBot	1072	\N
14891	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:46:31.055178	testBot	1072	\N
14892	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:46:31.057369	testBot	1072	\N
14893	{"message":"Job (id=1072) executed successfully","level":2}	2019-12-07 09:46:31.062063	testBot	1072	\N
14894	{"message":"Job (id=1072) execution started","level":2}	2019-12-07 09:46:31.112561	testBot	1072	\N
14895	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:46:31.114853	testBot	1072	\N
14896	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:46:31.125708	testBot	1072	\N
14897	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:46:31.128233	testBot	1072	\N
14898	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:46:31.137421	testBot	1072	\N
14899	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:46:31.140193	testBot	1072	\N
14900	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:46:31.142523	testBot	1072	\N
14901	{"message":"Job (id=1072) executed successfully","level":2}	2019-12-07 09:46:31.147789	testBot	1072	\N
14902	{"message":"Job (id=1072) execution started","level":2}	2019-12-07 09:46:31.19265	testBot	1072	\N
14903	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:46:31.19467	testBot	1072	\N
14904	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:46:31.205476	testBot	1072	\N
14905	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:46:31.207809	testBot	1072	\N
14906	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:46:31.217076	testBot	1072	\N
14907	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:46:31.219661	testBot	1072	\N
14908	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:46:31.221911	testBot	1072	\N
14909	{"message":"Job (id=1072) executed successfully","level":2}	2019-12-07 09:46:31.22632	testBot	1072	\N
14910	{"message":"Job (id=1072) execution started","level":2}	2019-12-07 09:46:31.26744	testBot	1072	\N
14911	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:46:31.269242	testBot	1072	\N
14912	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:46:31.278403	testBot	1072	\N
14913	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:46:31.288802	testBot	1072	\N
14914	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:46:31.297705	testBot	1072	\N
14915	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:46:31.30032	testBot	1072	\N
14916	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:46:31.302605	testBot	1072	\N
14917	{"message":"Job (id=1072) failed'","level":0}	2019-12-07 09:46:31.30735	testBot	1072	\N
14918	{"message":"Job (id=1072) execution started","level":2}	2019-12-07 09:46:31.349602	testBot	1072	\N
14919	{"message":"No any steps were found for job (id=1072)","level":0}	2019-12-07 09:46:31.352111	testBot	1072	\N
14920	{"message":"Job (id=1072) executed successfully","level":2}	2019-12-07 09:46:31.355902	testBot	1072	\N
14921	{"message":"Job (id=1074) execution started","level":2}	2019-12-07 09:48:53.709269	testBot	1074	\N
14922	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:48:53.714162	testBot	1074	\N
14923	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:48:53.73369	testBot	1074	\N
14924	{"message":"Job (id=1074) executed successfully","level":2}	2019-12-07 09:48:53.740232	testBot	1074	\N
14925	{"message":"Job (id=1074) execution started","level":2}	2019-12-07 09:48:53.815785	testBot	1074	\N
14926	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:48:53.818128	testBot	1074	\N
14927	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:48:53.827449	testBot	1074	\N
14928	{"message":"Job (id=1074) failed'","level":0}	2019-12-07 09:48:53.832239	testBot	1074	\N
14929	{"message":"Job (id=1074) execution started","level":2}	2019-12-07 09:48:53.884776	testBot	1074	\N
14930	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:48:53.886979	testBot	1074	\N
14931	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:48:53.896533	testBot	1074	\N
14932	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:48:53.898786	testBot	1074	\N
14933	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:48:53.908858	testBot	1074	\N
14934	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:48:53.91108	testBot	1074	\N
14935	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:48:53.91508	testBot	1074	\N
14936	{"message":"Job (id=1074) failed'","level":0}	2019-12-07 09:48:53.925353	testBot	1074	\N
14937	{"message":"Job (id=1074) execution started","level":2}	2019-12-07 09:48:53.977244	testBot	1074	\N
14938	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:48:53.985518	testBot	1074	\N
14939	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:48:54.007519	testBot	1074	\N
14940	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:48:54.009935	testBot	1074	\N
14941	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:48:54.017745	testBot	1074	\N
14942	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:48:54.019726	testBot	1074	\N
14943	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:48:54.021795	testBot	1074	\N
14944	{"message":"Job (id=1074) executed successfully","level":2}	2019-12-07 09:48:54.025985	testBot	1074	\N
14945	{"message":"Job (id=1074) execution started","level":2}	2019-12-07 09:48:54.068241	testBot	1074	\N
14946	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:48:54.070072	testBot	1074	\N
14947	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:48:54.079704	testBot	1074	\N
14948	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:48:54.081624	testBot	1074	\N
14949	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:48:54.089053	testBot	1074	\N
14950	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:48:54.091152	testBot	1074	\N
14951	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:48:54.093083	testBot	1074	\N
14952	{"message":"Job (id=1074) executed successfully","level":2}	2019-12-07 09:48:54.097349	testBot	1074	\N
14953	{"message":"Job (id=1074) execution started","level":2}	2019-12-07 09:48:54.141206	testBot	1074	\N
14954	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:48:54.142969	testBot	1074	\N
14955	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:48:54.151755	testBot	1074	\N
14956	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:48:54.153875	testBot	1074	\N
14957	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:48:54.161403	testBot	1074	\N
14958	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:48:54.163664	testBot	1074	\N
14959	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:48:54.166742	testBot	1074	\N
14960	{"message":"Job (id=1074) executed successfully","level":2}	2019-12-07 09:48:54.171379	testBot	1074	\N
14961	{"message":"Job (id=1074) execution started","level":2}	2019-12-07 09:48:54.220367	testBot	1074	\N
14962	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:48:54.222757	testBot	1074	\N
14963	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:48:54.232425	testBot	1074	\N
14964	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:48:54.234575	testBot	1074	\N
14965	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:48:54.242703	testBot	1074	\N
14966	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:48:54.249897	testBot	1074	\N
14967	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:48:54.252193	testBot	1074	\N
14968	{"message":"Job (id=1074) executed successfully","level":2}	2019-12-07 09:48:54.25684	testBot	1074	\N
14969	{"message":"Job (id=1074) execution started","level":2}	2019-12-07 09:48:54.297072	testBot	1074	\N
14970	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:48:54.298911	testBot	1074	\N
14971	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:48:54.307243	testBot	1074	\N
14972	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:48:54.30931	testBot	1074	\N
14973	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:48:54.316948	testBot	1074	\N
14974	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:48:54.319015	testBot	1074	\N
14975	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:48:54.321115	testBot	1074	\N
14976	{"message":"Job (id=1074) failed'","level":0}	2019-12-07 09:48:54.324929	testBot	1074	\N
14977	{"message":"Job (id=1074) execution started","level":2}	2019-12-07 09:48:54.367229	testBot	1074	\N
14978	{"message":"No any steps were found for job (id=1074)","level":0}	2019-12-07 09:48:54.369605	testBot	1074	\N
14979	{"message":"Job (id=1074) executed successfully","level":2}	2019-12-07 09:48:54.373934	testBot	1074	\N
14980	{"message":"Job (id=1076) execution started","level":2}	2019-12-07 09:50:51.652188	testBot	1076	\N
14981	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:50:51.663076	testBot	1076	\N
14982	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:50:51.674934	testBot	1076	\N
14983	{"message":"Job (id=1076) executed successfully","level":2}	2019-12-07 09:50:51.681282	testBot	1076	\N
14984	{"message":"Job (id=1076) execution started","level":2}	2019-12-07 09:50:51.756201	testBot	1076	\N
14985	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:50:51.757974	testBot	1076	\N
14986	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:50:51.766785	testBot	1076	\N
14987	{"message":"Job (id=1076) failed'","level":0}	2019-12-07 09:50:51.771223	testBot	1076	\N
14988	{"message":"Job (id=1076) execution started","level":2}	2019-12-07 09:50:51.823255	testBot	1076	\N
14989	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:50:51.825173	testBot	1076	\N
14990	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:50:51.834882	testBot	1076	\N
14991	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:50:51.836883	testBot	1076	\N
14992	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:50:51.843915	testBot	1076	\N
14993	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:50:51.84598	testBot	1076	\N
14994	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:50:51.850132	testBot	1076	\N
14995	{"message":"Job (id=1076) failed'","level":0}	2019-12-07 09:50:51.854369	testBot	1076	\N
14996	{"message":"Job (id=1076) execution started","level":2}	2019-12-07 09:50:51.899497	testBot	1076	\N
14997	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:50:51.901554	testBot	1076	\N
14998	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:50:51.911627	testBot	1076	\N
14999	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:50:51.9138	testBot	1076	\N
15000	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:50:51.92214	testBot	1076	\N
15001	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:50:51.924474	testBot	1076	\N
15002	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:50:51.926876	testBot	1076	\N
15003	{"message":"Job (id=1076) executed successfully","level":2}	2019-12-07 09:50:51.931856	testBot	1076	\N
15004	{"message":"Job (id=1076) execution started","level":2}	2019-12-07 09:50:51.978314	testBot	1076	\N
15005	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:50:51.980392	testBot	1076	\N
15006	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:50:51.990683	testBot	1076	\N
15007	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:50:51.992981	testBot	1076	\N
15008	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:50:52.003389	testBot	1076	\N
15009	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:50:52.005959	testBot	1076	\N
15010	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:50:52.0083	testBot	1076	\N
15011	{"message":"Job (id=1076) executed successfully","level":2}	2019-12-07 09:50:52.013363	testBot	1076	\N
15012	{"message":"Job (id=1076) execution started","level":2}	2019-12-07 09:50:52.06283	testBot	1076	\N
15013	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:50:52.064894	testBot	1076	\N
15014	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:50:52.075848	testBot	1076	\N
15015	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:50:52.078304	testBot	1076	\N
15016	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:50:52.086192	testBot	1076	\N
15017	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:50:52.088543	testBot	1076	\N
15018	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:50:52.090703	testBot	1076	\N
15019	{"message":"Job (id=1076) executed successfully","level":2}	2019-12-07 09:50:52.094713	testBot	1076	\N
15020	{"message":"Job (id=1076) execution started","level":2}	2019-12-07 09:50:52.13629	testBot	1076	\N
15021	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:50:52.138541	testBot	1076	\N
15022	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:50:52.148889	testBot	1076	\N
15023	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:50:52.151066	testBot	1076	\N
15024	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:50:52.159937	testBot	1076	\N
15025	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:50:52.162756	testBot	1076	\N
15026	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:50:52.1652	testBot	1076	\N
15027	{"message":"Job (id=1076) executed successfully","level":2}	2019-12-07 09:50:52.170031	testBot	1076	\N
15028	{"message":"Job (id=1076) execution started","level":2}	2019-12-07 09:50:52.213898	testBot	1076	\N
15029	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:50:52.215678	testBot	1076	\N
15030	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:50:52.225003	testBot	1076	\N
15031	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:50:52.226995	testBot	1076	\N
15032	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:50:52.235126	testBot	1076	\N
15033	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:50:52.237716	testBot	1076	\N
15034	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:50:52.240413	testBot	1076	\N
15035	{"message":"Job (id=1076) failed'","level":0}	2019-12-07 09:50:52.244921	testBot	1076	\N
15036	{"message":"Job (id=1076) execution started","level":2}	2019-12-07 09:50:52.289898	testBot	1076	\N
15037	{"message":"No any steps were found for job (id=1076)","level":0}	2019-12-07 09:50:52.292324	testBot	1076	\N
15038	{"message":"Job (id=1076) executed successfully","level":2}	2019-12-07 09:50:52.301995	testBot	1076	\N
15039	{"message":"Job (id=1078) execution started","level":2}	2019-12-07 09:51:40.413642	testBot	1078	\N
15040	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:51:40.420565	testBot	1078	\N
15041	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:51:40.434592	testBot	1078	\N
15042	{"message":"Job (id=1078) executed successfully","level":2}	2019-12-07 09:51:40.442477	testBot	1078	\N
15043	{"message":"Job (id=1078) execution started","level":2}	2019-12-07 09:51:40.522958	testBot	1078	\N
15044	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:51:40.524893	testBot	1078	\N
15045	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:51:40.535227	testBot	1078	\N
15046	{"message":"Job (id=1078) failed'","level":0}	2019-12-07 09:51:40.540105	testBot	1078	\N
15047	{"message":"Job (id=1078) execution started","level":2}	2019-12-07 09:51:40.60212	testBot	1078	\N
15048	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:51:40.604524	testBot	1078	\N
15049	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:51:40.614447	testBot	1078	\N
15050	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:51:40.616952	testBot	1078	\N
15051	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:51:40.626105	testBot	1078	\N
15052	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:51:40.628356	testBot	1078	\N
15053	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:51:40.63245	testBot	1078	\N
15054	{"message":"Job (id=1078) failed'","level":0}	2019-12-07 09:51:40.638196	testBot	1078	\N
15055	{"message":"Job (id=1078) execution started","level":2}	2019-12-07 09:51:40.688411	testBot	1078	\N
15056	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:51:40.690418	testBot	1078	\N
15057	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:51:40.700117	testBot	1078	\N
15058	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:51:40.702393	testBot	1078	\N
15059	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:51:40.711448	testBot	1078	\N
15060	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:51:40.714078	testBot	1078	\N
15061	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:51:40.716339	testBot	1078	\N
15062	{"message":"Job (id=1078) executed successfully","level":2}	2019-12-07 09:51:40.72019	testBot	1078	\N
15063	{"message":"Job (id=1078) execution started","level":2}	2019-12-07 09:51:40.774523	testBot	1078	\N
15064	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:51:40.776537	testBot	1078	\N
15065	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:51:40.784562	testBot	1078	\N
15066	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:51:40.786565	testBot	1078	\N
15067	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:51:40.794955	testBot	1078	\N
15068	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:51:40.797293	testBot	1078	\N
15069	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:51:40.799376	testBot	1078	\N
15070	{"message":"Job (id=1078) executed successfully","level":2}	2019-12-07 09:51:40.80387	testBot	1078	\N
15071	{"message":"Job (id=1078) execution started","level":2}	2019-12-07 09:51:40.847983	testBot	1078	\N
15072	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:51:40.849893	testBot	1078	\N
15073	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:51:40.859307	testBot	1078	\N
15074	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:51:40.861464	testBot	1078	\N
15075	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:51:40.869716	testBot	1078	\N
15076	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:51:40.87216	testBot	1078	\N
15077	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:51:40.874409	testBot	1078	\N
15078	{"message":"Job (id=1078) executed successfully","level":2}	2019-12-07 09:51:40.878933	testBot	1078	\N
15079	{"message":"Job (id=1078) execution started","level":2}	2019-12-07 09:51:40.925044	testBot	1078	\N
15080	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:51:40.926777	testBot	1078	\N
15081	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:51:40.935744	testBot	1078	\N
15082	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:51:40.937699	testBot	1078	\N
15083	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:51:40.945598	testBot	1078	\N
15084	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:51:40.947738	testBot	1078	\N
15085	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:51:40.949956	testBot	1078	\N
15086	{"message":"Job (id=1078) executed successfully","level":2}	2019-12-07 09:51:40.954293	testBot	1078	\N
15087	{"message":"Job (id=1078) execution started","level":2}	2019-12-07 09:51:41.005287	testBot	1078	\N
15088	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:51:41.007309	testBot	1078	\N
15089	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:51:41.023076	testBot	1078	\N
15090	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:51:41.025654	testBot	1078	\N
15091	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:51:41.033956	testBot	1078	\N
15092	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:51:41.036201	testBot	1078	\N
15093	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:51:41.038106	testBot	1078	\N
15094	{"message":"Job (id=1078) failed'","level":0}	2019-12-07 09:51:41.042638	testBot	1078	\N
15095	{"message":"Job (id=1078) execution started","level":2}	2019-12-07 09:51:41.083318	testBot	1078	\N
15096	{"message":"No any steps were found for job (id=1078)","level":0}	2019-12-07 09:51:41.085834	testBot	1078	\N
15097	{"message":"Job (id=1078) executed successfully","level":2}	2019-12-07 09:51:41.089764	testBot	1078	\N
15098	{"message":"Job (id=1082) execution started","level":2}	2019-12-07 09:53:19.327051	testBot	1082	\N
15099	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:53:19.333413	testBot	1082	\N
15100	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:53:19.345115	testBot	1082	\N
15101	{"message":"Job (id=1082) executed successfully","level":2}	2019-12-07 09:53:19.351926	testBot	1082	\N
15102	{"message":"Job (id=1082) execution started","level":2}	2019-12-07 09:53:19.425777	testBot	1082	\N
15103	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:53:19.427657	testBot	1082	\N
15104	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:53:19.436245	testBot	1082	\N
15105	{"message":"Job (id=1082) failed'","level":0}	2019-12-07 09:53:19.44137	testBot	1082	\N
15106	{"message":"Job (id=1082) execution started","level":2}	2019-12-07 09:53:19.493151	testBot	1082	\N
15107	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:53:19.495019	testBot	1082	\N
15108	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:53:19.504129	testBot	1082	\N
15109	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:53:19.506374	testBot	1082	\N
15110	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:53:19.516109	testBot	1082	\N
15111	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:53:19.518792	testBot	1082	\N
15112	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:53:19.523203	testBot	1082	\N
15113	{"message":"Job (id=1082) failed'","level":0}	2019-12-07 09:53:19.529236	testBot	1082	\N
15114	{"message":"Job (id=1082) execution started","level":2}	2019-12-07 09:53:19.575392	testBot	1082	\N
15115	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:53:19.577329	testBot	1082	\N
15116	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:53:19.598067	testBot	1082	\N
15117	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:53:19.600335	testBot	1082	\N
15118	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:53:19.610419	testBot	1082	\N
15119	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:53:19.613198	testBot	1082	\N
15120	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:53:19.616262	testBot	1082	\N
15121	{"message":"Job (id=1082) executed successfully","level":2}	2019-12-07 09:53:19.622004	testBot	1082	\N
15122	{"message":"Job (id=1082) execution started","level":2}	2019-12-07 09:53:19.664412	testBot	1082	\N
15123	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:53:19.666035	testBot	1082	\N
15124	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:53:19.673706	testBot	1082	\N
15125	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:53:19.675557	testBot	1082	\N
15126	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:53:19.681602	testBot	1082	\N
15127	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:53:19.68349	testBot	1082	\N
15128	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:53:19.68519	testBot	1082	\N
15129	{"message":"Job (id=1082) executed successfully","level":2}	2019-12-07 09:53:19.688849	testBot	1082	\N
15130	{"message":"Job (id=1082) execution started","level":2}	2019-12-07 09:53:19.732638	testBot	1082	\N
15131	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:53:19.734538	testBot	1082	\N
15132	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:53:19.742347	testBot	1082	\N
15133	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:53:19.744031	testBot	1082	\N
15134	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:53:19.750231	testBot	1082	\N
15135	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:53:19.752401	testBot	1082	\N
15136	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:53:19.754572	testBot	1082	\N
15137	{"message":"Job (id=1082) executed successfully","level":2}	2019-12-07 09:53:19.758642	testBot	1082	\N
15138	{"message":"Job (id=1082) execution started","level":2}	2019-12-07 09:53:19.803106	testBot	1082	\N
15139	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:53:19.805122	testBot	1082	\N
15140	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:53:19.814812	testBot	1082	\N
15141	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:53:19.816946	testBot	1082	\N
15142	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:53:19.824305	testBot	1082	\N
15143	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:53:19.826567	testBot	1082	\N
15144	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:53:19.828871	testBot	1082	\N
15145	{"message":"Job (id=1082) executed successfully","level":2}	2019-12-07 09:53:19.833312	testBot	1082	\N
15146	{"message":"Job (id=1082) execution started","level":2}	2019-12-07 09:53:19.87286	testBot	1082	\N
15147	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:53:19.874617	testBot	1082	\N
15148	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:53:19.883964	testBot	1082	\N
15149	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:53:19.886222	testBot	1082	\N
15150	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:53:19.894403	testBot	1082	\N
15151	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:53:19.896938	testBot	1082	\N
15152	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:53:19.899046	testBot	1082	\N
15153	{"message":"Job (id=1082) failed'","level":0}	2019-12-07 09:53:19.903313	testBot	1082	\N
15154	{"message":"Job (id=1082) execution started","level":2}	2019-12-07 09:53:19.951923	testBot	1082	\N
15155	{"message":"No any steps were found for job (id=1082)","level":0}	2019-12-07 09:53:19.954451	testBot	1082	\N
15156	{"message":"Job (id=1082) executed successfully","level":2}	2019-12-07 09:53:19.958693	testBot	1082	\N
15157	{"message":"Job (id=1086) execution started","level":2}	2019-12-07 09:55:23.029433	testBot	1086	\N
15158	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:55:23.033976	testBot	1086	\N
15159	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:55:23.044876	testBot	1086	\N
15160	{"message":"Job (id=1086) executed successfully","level":2}	2019-12-07 09:55:23.051083	testBot	1086	\N
15161	{"message":"Job (id=1086) execution started","level":2}	2019-12-07 09:55:23.141981	testBot	1086	\N
15162	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:55:23.144235	testBot	1086	\N
15163	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:55:23.154787	testBot	1086	\N
15164	{"message":"Job (id=1086) failed'","level":0}	2019-12-07 09:55:23.159444	testBot	1086	\N
15165	{"message":"Job (id=1086) execution started","level":2}	2019-12-07 09:55:23.222974	testBot	1086	\N
15166	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:55:23.224982	testBot	1086	\N
15167	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:55:23.23424	testBot	1086	\N
15168	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:55:23.236137	testBot	1086	\N
15169	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:55:23.243265	testBot	1086	\N
15170	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:55:23.245715	testBot	1086	\N
15171	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:55:23.249364	testBot	1086	\N
15172	{"message":"Job (id=1086) failed'","level":0}	2019-12-07 09:55:23.254127	testBot	1086	\N
15173	{"message":"Job (id=1086) execution started","level":2}	2019-12-07 09:55:23.301912	testBot	1086	\N
15174	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:55:23.30381	testBot	1086	\N
15175	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:55:23.312321	testBot	1086	\N
15176	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:55:23.314476	testBot	1086	\N
15177	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:55:23.322311	testBot	1086	\N
15178	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:55:23.324322	testBot	1086	\N
15179	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:55:23.326389	testBot	1086	\N
15180	{"message":"Job (id=1086) executed successfully","level":2}	2019-12-07 09:55:23.330459	testBot	1086	\N
15181	{"message":"Job (id=1086) execution started","level":2}	2019-12-07 09:55:23.379268	testBot	1086	\N
15182	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:55:23.38111	testBot	1086	\N
15183	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:55:23.390484	testBot	1086	\N
15184	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:55:23.392489	testBot	1086	\N
15185	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:55:23.401109	testBot	1086	\N
15186	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:55:23.403356	testBot	1086	\N
15187	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:55:23.40569	testBot	1086	\N
15188	{"message":"Job (id=1086) executed successfully","level":2}	2019-12-07 09:55:23.410856	testBot	1086	\N
15189	{"message":"Job (id=1086) execution started","level":2}	2019-12-07 09:55:23.457698	testBot	1086	\N
15190	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:55:23.459764	testBot	1086	\N
15191	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:55:23.470097	testBot	1086	\N
15192	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:55:23.47216	testBot	1086	\N
15193	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:55:23.480181	testBot	1086	\N
15194	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:55:23.492736	testBot	1086	\N
15195	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:55:23.495455	testBot	1086	\N
15196	{"message":"Job (id=1086) executed successfully","level":2}	2019-12-07 09:55:23.500493	testBot	1086	\N
15197	{"message":"Job (id=1086) execution started","level":2}	2019-12-07 09:55:23.545396	testBot	1086	\N
15198	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:55:23.547342	testBot	1086	\N
15199	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:55:23.556785	testBot	1086	\N
15200	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:55:23.558726	testBot	1086	\N
15201	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:55:23.56735	testBot	1086	\N
15202	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:55:23.569311	testBot	1086	\N
15203	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:55:23.571064	testBot	1086	\N
15204	{"message":"Job (id=1086) executed successfully","level":2}	2019-12-07 09:55:23.575205	testBot	1086	\N
15205	{"message":"Job (id=1086) execution started","level":2}	2019-12-07 09:55:23.616911	testBot	1086	\N
15206	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:55:23.618751	testBot	1086	\N
15207	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:55:23.628108	testBot	1086	\N
15208	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:55:23.630266	testBot	1086	\N
15209	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:55:23.639369	testBot	1086	\N
15210	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:55:23.642081	testBot	1086	\N
15211	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:55:23.644087	testBot	1086	\N
15212	{"message":"Job (id=1086) failed'","level":0}	2019-12-07 09:55:23.648393	testBot	1086	\N
15213	{"message":"Job (id=1086) execution started","level":2}	2019-12-07 09:55:23.693222	testBot	1086	\N
15214	{"message":"No any steps were found for job (id=1086)","level":0}	2019-12-07 09:55:23.696292	testBot	1086	\N
15215	{"message":"Job (id=1086) executed successfully","level":2}	2019-12-07 09:55:23.701625	testBot	1086	\N
15216	{"message":"Job (id=1090) execution started","level":2}	2019-12-07 09:59:08.704962	testBot	1090	\N
15217	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:59:08.710829	testBot	1090	\N
15218	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:59:08.722935	testBot	1090	\N
15219	{"message":"Job (id=1090) executed successfully","level":2}	2019-12-07 09:59:08.72977	testBot	1090	\N
15220	{"message":"Job (id=1090) execution started","level":2}	2019-12-07 09:59:08.810662	testBot	1090	\N
15221	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:59:08.81256	testBot	1090	\N
15222	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:59:08.822336	testBot	1090	\N
15223	{"message":"Job (id=1090) failed'","level":0}	2019-12-07 09:59:08.826099	testBot	1090	\N
15224	{"message":"Job (id=1090) execution started","level":2}	2019-12-07 09:59:08.875765	testBot	1090	\N
15225	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:59:08.878002	testBot	1090	\N
15226	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:59:08.888797	testBot	1090	\N
15227	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:59:08.890832	testBot	1090	\N
15228	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:59:08.900768	testBot	1090	\N
15229	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:59:08.90329	testBot	1090	\N
15230	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:59:08.907813	testBot	1090	\N
15231	{"message":"Job (id=1090) failed'","level":0}	2019-12-07 09:59:08.912653	testBot	1090	\N
15232	{"message":"Job (id=1090) execution started","level":2}	2019-12-07 09:59:08.960405	testBot	1090	\N
15233	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:59:08.962519	testBot	1090	\N
15234	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:59:08.972396	testBot	1090	\N
15235	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:59:08.975224	testBot	1090	\N
15236	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:59:08.984368	testBot	1090	\N
15237	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:59:08.986679	testBot	1090	\N
15238	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:59:08.989167	testBot	1090	\N
15239	{"message":"Job (id=1090) executed successfully","level":2}	2019-12-07 09:59:08.994324	testBot	1090	\N
15240	{"message":"Job (id=1090) execution started","level":2}	2019-12-07 09:59:09.046949	testBot	1090	\N
15241	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:59:09.049127	testBot	1090	\N
15242	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:59:09.057861	testBot	1090	\N
15243	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:59:09.059734	testBot	1090	\N
15244	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:59:09.066312	testBot	1090	\N
15245	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:59:09.06826	testBot	1090	\N
15246	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:59:09.070061	testBot	1090	\N
15247	{"message":"Job (id=1090) executed successfully","level":2}	2019-12-07 09:59:09.073624	testBot	1090	\N
15248	{"message":"Job (id=1090) execution started","level":2}	2019-12-07 09:59:09.12045	testBot	1090	\N
15249	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:59:09.122482	testBot	1090	\N
15250	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:59:09.133117	testBot	1090	\N
15251	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:59:09.135374	testBot	1090	\N
15252	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:59:09.144032	testBot	1090	\N
15253	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:59:09.146309	testBot	1090	\N
15254	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:59:09.148747	testBot	1090	\N
15255	{"message":"Job (id=1090) executed successfully","level":2}	2019-12-07 09:59:09.153484	testBot	1090	\N
15256	{"message":"Job (id=1090) execution started","level":2}	2019-12-07 09:59:09.195828	testBot	1090	\N
15257	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:59:09.19795	testBot	1090	\N
15258	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:59:09.208125	testBot	1090	\N
15259	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:59:09.210228	testBot	1090	\N
15260	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:59:09.218086	testBot	1090	\N
15261	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:59:09.220467	testBot	1090	\N
15262	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:59:09.223052	testBot	1090	\N
15263	{"message":"Job (id=1090) executed successfully","level":2}	2019-12-07 09:59:09.227558	testBot	1090	\N
15264	{"message":"Job (id=1090) execution started","level":2}	2019-12-07 09:59:09.266893	testBot	1090	\N
15265	{"message":"Executing step 'step1'","level":2}	2019-12-07 09:59:09.268843	testBot	1090	\N
15266	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 09:59:09.284768	testBot	1090	\N
15267	{"message":"Executing step 'step2'","level":2}	2019-12-07 09:59:09.286848	testBot	1090	\N
15268	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 09:59:09.295693	testBot	1090	\N
15269	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 09:59:09.298175	testBot	1090	\N
15270	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 09:59:09.300548	testBot	1090	\N
15271	{"message":"Job (id=1090) failed'","level":0}	2019-12-07 09:59:09.305551	testBot	1090	\N
15272	{"message":"Job (id=1090) execution started","level":2}	2019-12-07 09:59:09.346632	testBot	1090	\N
15273	{"message":"No any steps were found for job (id=1090)","level":0}	2019-12-07 09:59:09.349029	testBot	1090	\N
15274	{"message":"Job (id=1090) executed successfully","level":2}	2019-12-07 09:59:09.352739	testBot	1090	\N
15275	{"message":"Job (id=1094) execution started","level":2}	2019-12-07 10:00:22.445505	testBot	1094	\N
15276	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:00:22.451816	testBot	1094	\N
15277	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:00:22.464067	testBot	1094	\N
15278	{"message":"Job (id=1094) executed successfully","level":2}	2019-12-07 10:00:22.472776	testBot	1094	\N
15279	{"message":"Job (id=1094) execution started","level":2}	2019-12-07 10:00:22.552384	testBot	1094	\N
15280	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:00:22.554533	testBot	1094	\N
15281	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:00:22.564345	testBot	1094	\N
15282	{"message":"Job (id=1094) failed'","level":0}	2019-12-07 10:00:22.569532	testBot	1094	\N
15283	{"message":"Job (id=1094) execution started","level":2}	2019-12-07 10:00:22.622744	testBot	1094	\N
15284	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:00:22.624633	testBot	1094	\N
15285	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:00:22.633194	testBot	1094	\N
15286	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:00:22.635906	testBot	1094	\N
15287	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:00:22.644189	testBot	1094	\N
15288	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:00:22.646654	testBot	1094	\N
15289	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:00:22.650975	testBot	1094	\N
15290	{"message":"Job (id=1094) failed'","level":0}	2019-12-07 10:00:22.656045	testBot	1094	\N
15291	{"message":"Job (id=1094) execution started","level":2}	2019-12-07 10:00:22.701616	testBot	1094	\N
15292	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:00:22.703632	testBot	1094	\N
15293	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:00:22.713141	testBot	1094	\N
15294	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:00:22.715343	testBot	1094	\N
15295	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:00:22.724127	testBot	1094	\N
15296	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:00:22.726254	testBot	1094	\N
15297	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:00:22.729493	testBot	1094	\N
15298	{"message":"Job (id=1094) executed successfully","level":2}	2019-12-07 10:00:22.734564	testBot	1094	\N
15299	{"message":"Job (id=1094) execution started","level":2}	2019-12-07 10:00:22.777154	testBot	1094	\N
15300	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:00:22.779345	testBot	1094	\N
15301	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:00:22.788634	testBot	1094	\N
15302	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:00:22.790988	testBot	1094	\N
15303	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:00:22.800059	testBot	1094	\N
15304	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:00:22.808689	testBot	1094	\N
15305	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:00:22.81118	testBot	1094	\N
15306	{"message":"Job (id=1094) executed successfully","level":2}	2019-12-07 10:00:22.81691	testBot	1094	\N
15307	{"message":"Job (id=1094) execution started","level":2}	2019-12-07 10:00:22.864172	testBot	1094	\N
15308	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:00:22.866208	testBot	1094	\N
15309	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:00:22.875743	testBot	1094	\N
15310	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:00:22.878241	testBot	1094	\N
15311	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:00:22.885718	testBot	1094	\N
15312	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:00:22.888099	testBot	1094	\N
15313	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:00:22.890582	testBot	1094	\N
15314	{"message":"Job (id=1094) executed successfully","level":2}	2019-12-07 10:00:22.894766	testBot	1094	\N
15315	{"message":"Job (id=1094) execution started","level":2}	2019-12-07 10:00:22.935703	testBot	1094	\N
15316	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:00:22.938012	testBot	1094	\N
15317	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:00:22.94841	testBot	1094	\N
15318	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:00:22.950858	testBot	1094	\N
15319	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:00:22.960773	testBot	1094	\N
15320	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:00:22.963102	testBot	1094	\N
15321	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:00:22.965383	testBot	1094	\N
15322	{"message":"Job (id=1094) executed successfully","level":2}	2019-12-07 10:00:22.970526	testBot	1094	\N
15323	{"message":"Job (id=1094) execution started","level":2}	2019-12-07 10:00:23.013917	testBot	1094	\N
15324	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:00:23.015858	testBot	1094	\N
15325	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:00:23.024909	testBot	1094	\N
15326	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:00:23.027215	testBot	1094	\N
15327	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:00:23.03352	testBot	1094	\N
15328	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:00:23.035445	testBot	1094	\N
15329	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:00:23.03735	testBot	1094	\N
15330	{"message":"Job (id=1094) failed'","level":0}	2019-12-07 10:00:23.041032	testBot	1094	\N
15331	{"message":"Job (id=1094) execution started","level":2}	2019-12-07 10:00:23.090633	testBot	1094	\N
15332	{"message":"No any steps were found for job (id=1094)","level":0}	2019-12-07 10:00:23.093387	testBot	1094	\N
15333	{"message":"Job (id=1094) executed successfully","level":2}	2019-12-07 10:00:23.097317	testBot	1094	\N
15334	{"message":"Job (id=1098) execution started","level":2}	2019-12-07 10:01:37.089409	testBot	1098	\N
15335	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:01:37.095229	testBot	1098	\N
15336	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:01:37.107086	testBot	1098	\N
15337	{"message":"Job (id=1098) executed successfully","level":2}	2019-12-07 10:01:37.117089	testBot	1098	\N
15338	{"message":"Job (id=1098) execution started","level":2}	2019-12-07 10:01:37.196368	testBot	1098	\N
15339	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:01:37.198381	testBot	1098	\N
15340	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:01:37.208244	testBot	1098	\N
15341	{"message":"Job (id=1098) failed'","level":0}	2019-12-07 10:01:37.212775	testBot	1098	\N
15342	{"message":"Job (id=1098) execution started","level":2}	2019-12-07 10:01:37.267484	testBot	1098	\N
15343	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:01:37.269273	testBot	1098	\N
15344	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:01:37.278061	testBot	1098	\N
15345	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:01:37.280477	testBot	1098	\N
15346	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:01:37.2884	testBot	1098	\N
15347	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:01:37.290738	testBot	1098	\N
15348	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:01:37.295008	testBot	1098	\N
15349	{"message":"Job (id=1098) failed'","level":0}	2019-12-07 10:01:37.300479	testBot	1098	\N
15350	{"message":"Job (id=1098) execution started","level":2}	2019-12-07 10:01:37.351001	testBot	1098	\N
15351	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:01:37.352962	testBot	1098	\N
15352	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:01:37.361871	testBot	1098	\N
15353	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:01:37.364092	testBot	1098	\N
15354	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:01:37.372422	testBot	1098	\N
15355	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:01:37.374549	testBot	1098	\N
15356	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:01:37.376706	testBot	1098	\N
15357	{"message":"Job (id=1098) executed successfully","level":2}	2019-12-07 10:01:37.38107	testBot	1098	\N
15358	{"message":"Job (id=1098) execution started","level":2}	2019-12-07 10:01:37.425479	testBot	1098	\N
15359	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:01:37.427585	testBot	1098	\N
15360	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:01:37.438412	testBot	1098	\N
15361	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:01:37.440405	testBot	1098	\N
15362	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:01:37.449391	testBot	1098	\N
15363	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:01:37.451653	testBot	1098	\N
15364	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:01:37.454475	testBot	1098	\N
15365	{"message":"Job (id=1098) executed successfully","level":2}	2019-12-07 10:01:37.460348	testBot	1098	\N
15366	{"message":"Job (id=1098) execution started","level":2}	2019-12-07 10:01:37.511029	testBot	1098	\N
15367	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:01:37.513012	testBot	1098	\N
15368	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:01:37.521978	testBot	1098	\N
15369	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:01:37.524099	testBot	1098	\N
15370	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:01:37.533053	testBot	1098	\N
15371	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:01:37.535454	testBot	1098	\N
15372	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:01:37.538267	testBot	1098	\N
15373	{"message":"Job (id=1098) executed successfully","level":2}	2019-12-07 10:01:37.543488	testBot	1098	\N
15374	{"message":"Job (id=1098) execution started","level":2}	2019-12-07 10:01:37.589651	testBot	1098	\N
15375	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:01:37.59187	testBot	1098	\N
15376	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:01:37.602404	testBot	1098	\N
15377	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:01:37.604423	testBot	1098	\N
15378	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:01:37.619209	testBot	1098	\N
15379	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:01:37.621544	testBot	1098	\N
15380	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:01:37.624233	testBot	1098	\N
15381	{"message":"Job (id=1098) executed successfully","level":2}	2019-12-07 10:01:37.629384	testBot	1098	\N
15382	{"message":"Job (id=1098) execution started","level":2}	2019-12-07 10:01:37.671547	testBot	1098	\N
15383	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:01:37.673372	testBot	1098	\N
15384	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:01:37.683178	testBot	1098	\N
15385	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:01:37.685146	testBot	1098	\N
15386	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:01:37.693194	testBot	1098	\N
15387	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:01:37.695191	testBot	1098	\N
15388	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:01:37.697386	testBot	1098	\N
15389	{"message":"Job (id=1098) failed'","level":0}	2019-12-07 10:01:37.702089	testBot	1098	\N
15390	{"message":"Job (id=1098) execution started","level":2}	2019-12-07 10:01:37.744438	testBot	1098	\N
15391	{"message":"No any steps were found for job (id=1098)","level":0}	2019-12-07 10:01:37.746949	testBot	1098	\N
15392	{"message":"Job (id=1098) executed successfully","level":2}	2019-12-07 10:01:37.750746	testBot	1098	\N
15393	{"message":"Job (id=1102) execution started","level":2}	2019-12-07 10:02:32.800531	testBot	1102	\N
15394	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:02:32.805609	testBot	1102	\N
15395	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:02:32.81814	testBot	1102	\N
15396	{"message":"Job (id=1102) executed successfully","level":2}	2019-12-07 10:02:32.824374	testBot	1102	\N
15397	{"message":"Job (id=1102) execution started","level":2}	2019-12-07 10:02:32.899431	testBot	1102	\N
15398	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:02:32.901268	testBot	1102	\N
15399	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:02:32.910841	testBot	1102	\N
15400	{"message":"Job (id=1102) failed'","level":0}	2019-12-07 10:02:32.916808	testBot	1102	\N
15401	{"message":"Job (id=1102) execution started","level":2}	2019-12-07 10:02:32.968989	testBot	1102	\N
15402	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:02:32.970954	testBot	1102	\N
15403	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:02:32.980717	testBot	1102	\N
15404	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:02:32.983065	testBot	1102	\N
15405	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:02:32.992497	testBot	1102	\N
15406	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:02:32.99554	testBot	1102	\N
15407	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:02:32.99984	testBot	1102	\N
15408	{"message":"Job (id=1102) failed'","level":0}	2019-12-07 10:02:33.004474	testBot	1102	\N
15409	{"message":"Job (id=1102) execution started","level":2}	2019-12-07 10:02:33.05024	testBot	1102	\N
15410	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:02:33.052664	testBot	1102	\N
15411	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:02:33.063381	testBot	1102	\N
15412	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:02:33.065872	testBot	1102	\N
15413	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:02:33.072448	testBot	1102	\N
15414	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:02:33.074746	testBot	1102	\N
15415	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:02:33.077414	testBot	1102	\N
15416	{"message":"Job (id=1102) executed successfully","level":2}	2019-12-07 10:02:33.08255	testBot	1102	\N
15417	{"message":"Job (id=1102) execution started","level":2}	2019-12-07 10:02:33.131052	testBot	1102	\N
15418	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:02:33.133525	testBot	1102	\N
15419	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:02:33.143495	testBot	1102	\N
15420	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:02:33.145794	testBot	1102	\N
15421	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:02:33.154698	testBot	1102	\N
15422	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:02:33.157013	testBot	1102	\N
15423	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:02:33.159281	testBot	1102	\N
15424	{"message":"Job (id=1102) executed successfully","level":2}	2019-12-07 10:02:33.169693	testBot	1102	\N
15425	{"message":"Job (id=1102) execution started","level":2}	2019-12-07 10:02:33.217309	testBot	1102	\N
15426	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:02:33.219421	testBot	1102	\N
15427	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:02:33.229021	testBot	1102	\N
15428	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:02:33.231462	testBot	1102	\N
15429	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:02:33.241449	testBot	1102	\N
15430	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:02:33.243872	testBot	1102	\N
15431	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:02:33.24601	testBot	1102	\N
15432	{"message":"Job (id=1102) executed successfully","level":2}	2019-12-07 10:02:33.250129	testBot	1102	\N
15433	{"message":"Job (id=1102) execution started","level":2}	2019-12-07 10:02:33.293267	testBot	1102	\N
15434	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:02:33.295847	testBot	1102	\N
15435	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:02:33.306766	testBot	1102	\N
15436	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:02:33.309724	testBot	1102	\N
15437	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:02:33.319638	testBot	1102	\N
15438	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:02:33.322285	testBot	1102	\N
15439	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:02:33.325265	testBot	1102	\N
15440	{"message":"Job (id=1102) executed successfully","level":2}	2019-12-07 10:02:33.328975	testBot	1102	\N
15441	{"message":"Job (id=1102) execution started","level":2}	2019-12-07 10:02:33.373706	testBot	1102	\N
15442	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:02:33.375759	testBot	1102	\N
15443	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:02:33.385077	testBot	1102	\N
15444	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:02:33.387912	testBot	1102	\N
15445	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:02:33.397232	testBot	1102	\N
15446	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:02:33.399795	testBot	1102	\N
15447	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:02:33.402204	testBot	1102	\N
15448	{"message":"Job (id=1102) failed'","level":0}	2019-12-07 10:02:33.406609	testBot	1102	\N
15449	{"message":"Job (id=1102) execution started","level":2}	2019-12-07 10:02:33.448526	testBot	1102	\N
15450	{"message":"No any steps were found for job (id=1102)","level":0}	2019-12-07 10:02:33.450819	testBot	1102	\N
15451	{"message":"Job (id=1102) executed successfully","level":2}	2019-12-07 10:02:33.459506	testBot	1102	\N
15452	{"message":"Job (id=1106) execution started","level":2}	2019-12-07 10:05:41.054884	testBot	1106	\N
15453	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:05:41.064652	testBot	1106	\N
15454	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:05:41.077885	testBot	1106	\N
15455	{"message":"Job (id=1106) executed successfully","level":2}	2019-12-07 10:05:41.084906	testBot	1106	\N
15456	{"message":"Job (id=1106) execution started","level":2}	2019-12-07 10:05:41.160848	testBot	1106	\N
15457	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:05:41.168319	testBot	1106	\N
15458	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:05:41.188615	testBot	1106	\N
15459	{"message":"Job (id=1106) failed'","level":0}	2019-12-07 10:05:41.193195	testBot	1106	\N
15460	{"message":"Job (id=1106) execution started","level":2}	2019-12-07 10:05:41.245988	testBot	1106	\N
15461	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:05:41.248013	testBot	1106	\N
15462	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:05:41.25847	testBot	1106	\N
15463	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:05:41.260437	testBot	1106	\N
15464	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:05:41.267789	testBot	1106	\N
15465	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:05:41.270169	testBot	1106	\N
15466	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:05:41.274201	testBot	1106	\N
15467	{"message":"Job (id=1106) failed'","level":0}	2019-12-07 10:05:41.278434	testBot	1106	\N
15468	{"message":"Job (id=1106) execution started","level":2}	2019-12-07 10:05:41.324189	testBot	1106	\N
15469	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:05:41.32603	testBot	1106	\N
15470	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:05:41.33451	testBot	1106	\N
15471	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:05:41.337411	testBot	1106	\N
15472	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:05:41.346177	testBot	1106	\N
15473	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:05:41.348415	testBot	1106	\N
15474	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:05:41.350749	testBot	1106	\N
15475	{"message":"Job (id=1106) executed successfully","level":2}	2019-12-07 10:05:41.355533	testBot	1106	\N
15476	{"message":"Job (id=1106) execution started","level":2}	2019-12-07 10:05:41.400379	testBot	1106	\N
15477	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:05:41.402284	testBot	1106	\N
15478	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:05:41.411126	testBot	1106	\N
15479	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:05:41.413206	testBot	1106	\N
15480	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:05:41.419798	testBot	1106	\N
15481	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:05:41.421921	testBot	1106	\N
15482	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:05:41.423838	testBot	1106	\N
15483	{"message":"Job (id=1106) executed successfully","level":2}	2019-12-07 10:05:41.427804	testBot	1106	\N
15484	{"message":"Job (id=1106) execution started","level":2}	2019-12-07 10:05:41.474617	testBot	1106	\N
15485	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:05:41.476725	testBot	1106	\N
15486	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:05:41.487009	testBot	1106	\N
15487	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:05:41.489223	testBot	1106	\N
15488	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:05:41.499155	testBot	1106	\N
15489	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:05:41.501637	testBot	1106	\N
15490	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:05:41.50405	testBot	1106	\N
15491	{"message":"Job (id=1106) executed successfully","level":2}	2019-12-07 10:05:41.508219	testBot	1106	\N
15492	{"message":"Job (id=1106) execution started","level":2}	2019-12-07 10:05:41.552168	testBot	1106	\N
15493	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:05:41.553943	testBot	1106	\N
15494	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:05:41.562779	testBot	1106	\N
15495	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:05:41.565112	testBot	1106	\N
15496	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:05:41.573728	testBot	1106	\N
15497	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:05:41.576074	testBot	1106	\N
15498	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:05:41.578244	testBot	1106	\N
15499	{"message":"Job (id=1106) executed successfully","level":2}	2019-12-07 10:05:41.582774	testBot	1106	\N
15500	{"message":"Job (id=1106) execution started","level":2}	2019-12-07 10:05:41.62375	testBot	1106	\N
15501	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:05:41.625615	testBot	1106	\N
15502	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:05:41.634835	testBot	1106	\N
15503	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:05:41.636797	testBot	1106	\N
15504	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:05:41.645104	testBot	1106	\N
15505	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:05:41.647695	testBot	1106	\N
15506	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:05:41.649878	testBot	1106	\N
15507	{"message":"Job (id=1106) failed'","level":0}	2019-12-07 10:05:41.654213	testBot	1106	\N
15508	{"message":"Job (id=1106) execution started","level":2}	2019-12-07 10:05:41.706013	testBot	1106	\N
15509	{"message":"No any steps were found for job (id=1106)","level":0}	2019-12-07 10:05:41.708732	testBot	1106	\N
15510	{"message":"Job (id=1106) executed successfully","level":2}	2019-12-07 10:05:41.713015	testBot	1106	\N
15511	{"message":"Job (id=1113) execution started","level":2}	2019-12-07 10:08:53.346023	testBot	1113	\N
15512	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:08:53.350364	testBot	1113	\N
15513	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:08:53.372424	testBot	1113	\N
15514	{"message":"Job (id=1113) executed successfully","level":2}	2019-12-07 10:08:53.378653	testBot	1113	\N
15515	{"message":"Job (id=1113) execution started","level":2}	2019-12-07 10:08:53.463433	testBot	1113	\N
15516	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:08:53.465305	testBot	1113	\N
15517	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:08:53.476014	testBot	1113	\N
15518	{"message":"Job (id=1113) failed'","level":0}	2019-12-07 10:08:53.480367	testBot	1113	\N
15519	{"message":"Job (id=1113) execution started","level":2}	2019-12-07 10:08:53.536288	testBot	1113	\N
15520	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:08:53.538254	testBot	1113	\N
15521	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:08:53.547937	testBot	1113	\N
15522	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:08:53.549928	testBot	1113	\N
15523	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:08:53.558953	testBot	1113	\N
15524	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:08:53.561362	testBot	1113	\N
15525	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:08:53.565419	testBot	1113	\N
15526	{"message":"Job (id=1113) failed'","level":0}	2019-12-07 10:08:53.56959	testBot	1113	\N
15527	{"message":"Job (id=1113) execution started","level":2}	2019-12-07 10:08:53.625817	testBot	1113	\N
15528	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:08:53.628364	testBot	1113	\N
15529	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:08:53.644124	testBot	1113	\N
15530	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:08:53.64775	testBot	1113	\N
15531	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:08:53.657845	testBot	1113	\N
15532	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:08:53.660795	testBot	1113	\N
15533	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:08:53.663674	testBot	1113	\N
15534	{"message":"Job (id=1113) executed successfully","level":2}	2019-12-07 10:08:53.669056	testBot	1113	\N
15535	{"message":"Job (id=1113) execution started","level":2}	2019-12-07 10:08:53.715857	testBot	1113	\N
15536	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:08:53.717572	testBot	1113	\N
15537	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:08:53.732104	testBot	1113	\N
15538	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:08:53.734042	testBot	1113	\N
15539	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:08:53.741377	testBot	1113	\N
15540	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:08:53.743832	testBot	1113	\N
15541	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:08:53.746235	testBot	1113	\N
15542	{"message":"Job (id=1113) executed successfully","level":2}	2019-12-07 10:08:53.750966	testBot	1113	\N
15543	{"message":"Job (id=1113) execution started","level":2}	2019-12-07 10:08:53.800578	testBot	1113	\N
15544	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:08:53.802531	testBot	1113	\N
15545	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:08:53.811617	testBot	1113	\N
15546	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:08:53.813811	testBot	1113	\N
15547	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:08:53.82207	testBot	1113	\N
15548	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:08:53.824362	testBot	1113	\N
15549	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:08:53.826985	testBot	1113	\N
15550	{"message":"Job (id=1113) executed successfully","level":2}	2019-12-07 10:08:53.831194	testBot	1113	\N
15551	{"message":"Job (id=1113) execution started","level":2}	2019-12-07 10:08:53.873574	testBot	1113	\N
15552	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:08:53.875697	testBot	1113	\N
15553	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:08:53.894326	testBot	1113	\N
15554	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:08:53.89647	testBot	1113	\N
15555	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:08:53.905776	testBot	1113	\N
15556	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:08:53.908035	testBot	1113	\N
15557	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:08:53.910954	testBot	1113	\N
15558	{"message":"Job (id=1113) executed successfully","level":2}	2019-12-07 10:08:53.915472	testBot	1113	\N
15559	{"message":"Job (id=1113) execution started","level":2}	2019-12-07 10:08:53.965693	testBot	1113	\N
15560	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:08:53.967421	testBot	1113	\N
15561	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:08:53.976484	testBot	1113	\N
15562	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:08:53.978535	testBot	1113	\N
15563	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:08:53.987601	testBot	1113	\N
15564	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:08:53.989902	testBot	1113	\N
15565	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:08:53.992194	testBot	1113	\N
15566	{"message":"Job (id=1113) failed'","level":0}	2019-12-07 10:08:53.996667	testBot	1113	\N
15567	{"message":"Job (id=1113) execution started","level":2}	2019-12-07 10:08:54.039141	testBot	1113	\N
15568	{"message":"No any steps were found for job (id=1113)","level":0}	2019-12-07 10:08:54.041535	testBot	1113	\N
15569	{"message":"Job (id=1113) executed successfully","level":2}	2019-12-07 10:08:54.045958	testBot	1113	\N
15570	{"message":"Job (id=1117) execution started","level":2}	2019-12-07 10:15:28.44822	testBot	1117	\N
15571	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:15:28.452595	testBot	1117	\N
15572	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:15:28.46493	testBot	1117	\N
15573	{"message":"Job (id=1117) executed successfully","level":2}	2019-12-07 10:15:28.470943	testBot	1117	\N
15574	{"message":"Job (id=1117) execution started","level":2}	2019-12-07 10:15:28.545292	testBot	1117	\N
15575	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:15:28.54721	testBot	1117	\N
15576	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:15:28.556742	testBot	1117	\N
15577	{"message":"Job (id=1117) failed'","level":0}	2019-12-07 10:15:28.560819	testBot	1117	\N
15578	{"message":"Job (id=1117) execution started","level":2}	2019-12-07 10:15:28.612397	testBot	1117	\N
15579	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:15:28.614722	testBot	1117	\N
15580	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:15:28.623779	testBot	1117	\N
15581	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:15:28.626038	testBot	1117	\N
15582	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:28.63306	testBot	1117	\N
15583	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:15:28.634933	testBot	1117	\N
15584	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:28.637802	testBot	1117	\N
15585	{"message":"Job (id=1117) failed'","level":0}	2019-12-07 10:15:28.642117	testBot	1117	\N
15586	{"message":"Job (id=1117) execution started","level":2}	2019-12-07 10:15:28.686871	testBot	1117	\N
15587	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:15:28.688677	testBot	1117	\N
15588	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:15:28.697579	testBot	1117	\N
15589	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:15:28.699739	testBot	1117	\N
15590	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:28.707871	testBot	1117	\N
15591	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:15:28.710115	testBot	1117	\N
15592	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:28.712871	testBot	1117	\N
15593	{"message":"Job (id=1117) executed successfully","level":2}	2019-12-07 10:15:28.717718	testBot	1117	\N
15594	{"message":"Job (id=1117) execution started","level":2}	2019-12-07 10:15:28.765259	testBot	1117	\N
15595	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:15:28.767705	testBot	1117	\N
15596	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:15:28.778085	testBot	1117	\N
15597	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:15:28.780552	testBot	1117	\N
15598	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:28.7921	testBot	1117	\N
15599	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:15:28.794489	testBot	1117	\N
15600	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:28.796984	testBot	1117	\N
15601	{"message":"Job (id=1117) executed successfully","level":2}	2019-12-07 10:15:28.801865	testBot	1117	\N
15602	{"message":"Job (id=1117) execution started","level":2}	2019-12-07 10:15:28.849683	testBot	1117	\N
15603	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:15:28.851759	testBot	1117	\N
15604	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:15:28.861799	testBot	1117	\N
15605	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:15:28.865014	testBot	1117	\N
15606	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:28.873444	testBot	1117	\N
15607	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:15:28.875822	testBot	1117	\N
15608	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:15:28.878413	testBot	1117	\N
15609	{"message":"Job (id=1117) executed successfully","level":2}	2019-12-07 10:15:28.88277	testBot	1117	\N
15610	{"message":"Job (id=1117) execution started","level":2}	2019-12-07 10:15:28.922757	testBot	1117	\N
15611	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:15:28.924539	testBot	1117	\N
15612	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:15:28.933879	testBot	1117	\N
15613	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:15:28.935899	testBot	1117	\N
15614	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:28.94403	testBot	1117	\N
15615	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:15:28.946371	testBot	1117	\N
15616	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:15:28.948847	testBot	1117	\N
15617	{"message":"Job (id=1117) executed successfully","level":2}	2019-12-07 10:15:28.952994	testBot	1117	\N
15618	{"message":"Job (id=1117) execution started","level":2}	2019-12-07 10:15:28.996644	testBot	1117	\N
15619	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:15:28.998631	testBot	1117	\N
15620	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:15:29.007981	testBot	1117	\N
15621	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:15:29.010267	testBot	1117	\N
15622	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:29.019385	testBot	1117	\N
15623	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:15:29.021638	testBot	1117	\N
15624	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:15:29.024011	testBot	1117	\N
15625	{"message":"Job (id=1117) failed'","level":0}	2019-12-07 10:15:29.027597	testBot	1117	\N
15626	{"message":"Job (id=1117) execution started","level":2}	2019-12-07 10:15:29.066789	testBot	1117	\N
15627	{"message":"No any steps were found for job (id=1117)","level":0}	2019-12-07 10:15:29.068836	testBot	1117	\N
15628	{"message":"Job (id=1117) executed successfully","level":2}	2019-12-07 10:15:29.072313	testBot	1117	\N
15629	{"message":"Job (id=1117) execution started","level":2}	2019-12-07 10:15:29.103794	testBot	1117	\N
15630	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:15:29.105626	testBot	1117	\N
15631	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:15:29.115537	testBot	1117	\N
15632	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:15:29.11733	testBot	1117	\N
15633	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:29.125251	testBot	1117	\N
15634	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:15:29.127655	testBot	1117	\N
15635	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:15:30.146309	testBot	1117	\N
15636	{"message":"Job (id=1117) failed'","level":0}	2019-12-07 10:15:30.155398	testBot	1117	\N
15637	{"message":"Job (id=1121) execution started","level":2}	2019-12-07 10:16:22.080043	testBot	1121	\N
15638	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:16:22.084528	testBot	1121	\N
15639	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:16:22.096081	testBot	1121	\N
15640	{"message":"Job (id=1121) executed successfully","level":2}	2019-12-07 10:16:22.10247	testBot	1121	\N
15641	{"message":"Job (id=1121) execution started","level":2}	2019-12-07 10:16:22.178659	testBot	1121	\N
15642	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:16:22.180506	testBot	1121	\N
15643	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:16:22.195798	testBot	1121	\N
15644	{"message":"Job (id=1121) failed'","level":0}	2019-12-07 10:16:22.200576	testBot	1121	\N
15645	{"message":"Job (id=1121) execution started","level":2}	2019-12-07 10:16:22.259178	testBot	1121	\N
15646	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:16:22.27132	testBot	1121	\N
15647	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:16:22.283918	testBot	1121	\N
15648	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:16:22.286381	testBot	1121	\N
15649	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.296255	testBot	1121	\N
15650	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:16:22.299155	testBot	1121	\N
15651	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.303876	testBot	1121	\N
15652	{"message":"Job (id=1121) failed'","level":0}	2019-12-07 10:16:22.308221	testBot	1121	\N
15653	{"message":"Job (id=1121) execution started","level":2}	2019-12-07 10:16:22.350917	testBot	1121	\N
15654	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:16:22.352755	testBot	1121	\N
15655	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:16:22.361478	testBot	1121	\N
15656	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:16:22.363709	testBot	1121	\N
15657	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.372476	testBot	1121	\N
15658	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:16:22.374714	testBot	1121	\N
15659	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.378255	testBot	1121	\N
15660	{"message":"Job (id=1121) executed successfully","level":2}	2019-12-07 10:16:22.382018	testBot	1121	\N
15661	{"message":"Job (id=1121) execution started","level":2}	2019-12-07 10:16:22.426481	testBot	1121	\N
15662	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:16:22.428308	testBot	1121	\N
15663	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:16:22.43703	testBot	1121	\N
15664	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:16:22.439002	testBot	1121	\N
15665	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.447346	testBot	1121	\N
15666	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:16:22.449554	testBot	1121	\N
15667	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.451872	testBot	1121	\N
15668	{"message":"Job (id=1121) executed successfully","level":2}	2019-12-07 10:16:22.456417	testBot	1121	\N
15669	{"message":"Job (id=1121) execution started","level":2}	2019-12-07 10:16:22.501365	testBot	1121	\N
15670	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:16:22.503304	testBot	1121	\N
15671	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:16:22.512788	testBot	1121	\N
15672	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:16:22.515156	testBot	1121	\N
15673	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.524872	testBot	1121	\N
15674	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:16:22.527961	testBot	1121	\N
15675	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:16:22.530893	testBot	1121	\N
15676	{"message":"Job (id=1121) executed successfully","level":2}	2019-12-07 10:16:22.535813	testBot	1121	\N
15677	{"message":"Job (id=1121) execution started","level":2}	2019-12-07 10:16:22.576163	testBot	1121	\N
15678	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:16:22.578052	testBot	1121	\N
15679	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:16:22.587591	testBot	1121	\N
15680	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:16:22.589944	testBot	1121	\N
15681	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.599352	testBot	1121	\N
15682	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:16:22.602496	testBot	1121	\N
15683	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:16:22.605057	testBot	1121	\N
15684	{"message":"Job (id=1121) executed successfully","level":2}	2019-12-07 10:16:22.609829	testBot	1121	\N
15685	{"message":"Job (id=1121) execution started","level":2}	2019-12-07 10:16:22.652463	testBot	1121	\N
15686	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:16:22.654475	testBot	1121	\N
15687	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:16:22.664355	testBot	1121	\N
15688	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:16:22.666561	testBot	1121	\N
15689	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.67602	testBot	1121	\N
15690	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:16:22.678324	testBot	1121	\N
15691	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 10:16:22.680739	testBot	1121	\N
15692	{"message":"Job (id=1121) failed'","level":0}	2019-12-07 10:16:22.68485	testBot	1121	\N
15693	{"message":"Job (id=1121) execution started","level":2}	2019-12-07 10:16:22.7282	testBot	1121	\N
15694	{"message":"No any steps were found for job (id=1121)","level":0}	2019-12-07 10:16:22.730309	testBot	1121	\N
15695	{"message":"Job (id=1121) executed successfully","level":2}	2019-12-07 10:16:22.733577	testBot	1121	\N
15696	{"message":"Job (id=1121) execution started","level":2}	2019-12-07 10:16:22.760069	testBot	1121	\N
15697	{"message":"Executing step 'step1'","level":2}	2019-12-07 10:16:22.762078	testBot	1121	\N
15698	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 10:16:22.782125	testBot	1121	\N
15699	{"message":"Executing step 'step2'","level":2}	2019-12-07 10:16:22.784405	testBot	1121	\N
15700	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.793284	testBot	1121	\N
15701	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 10:16:22.795517	testBot	1121	\N
15702	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 10:16:22.797872	testBot	1121	\N
15703	{"message":"Job (id=1121) failed'","level":0}	2019-12-07 10:16:22.802052	testBot	1121	\N
15704	{"message":"Job (id=1125) execution started","level":2}	2019-12-07 20:40:39.553855	testBot	1125	\N
15705	{"message":"Executing step 'step1'","level":2}	2019-12-07 20:40:39.558393	testBot	1125	\N
15706	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 20:40:39.571409	testBot	1125	\N
15707	{"message":"Job (id=1125) executed successfully","level":2}	2019-12-07 20:40:39.589935	testBot	1125	\N
15708	{"message":"Job (id=1125) execution started","level":2}	2019-12-07 20:40:39.671066	testBot	1125	\N
15709	{"message":"Executing step 'step1'","level":2}	2019-12-07 20:40:39.673279	testBot	1125	\N
15710	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 20:40:39.684699	testBot	1125	\N
15711	{"message":"Job (id=1125) failed'","level":0}	2019-12-07 20:40:39.688782	testBot	1125	\N
15712	{"message":"Job (id=1125) execution started","level":2}	2019-12-07 20:40:39.746287	testBot	1125	\N
15713	{"message":"Executing step 'step1'","level":2}	2019-12-07 20:40:39.748815	testBot	1125	\N
15714	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 20:40:39.760144	testBot	1125	\N
15715	{"message":"Executing step 'step2'","level":2}	2019-12-07 20:40:39.762749	testBot	1125	\N
15716	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:39.773113	testBot	1125	\N
15717	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 20:40:39.775836	testBot	1125	\N
15718	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:39.779484	testBot	1125	\N
15719	{"message":"Job (id=1125) failed'","level":0}	2019-12-07 20:40:39.784585	testBot	1125	\N
15720	{"message":"Job (id=1125) execution started","level":2}	2019-12-07 20:40:39.829688	testBot	1125	\N
15721	{"message":"Executing step 'step1'","level":2}	2019-12-07 20:40:39.831447	testBot	1125	\N
15722	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 20:40:39.840082	testBot	1125	\N
15723	{"message":"Executing step 'step2'","level":2}	2019-12-07 20:40:39.842287	testBot	1125	\N
15724	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:39.852911	testBot	1125	\N
15725	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 20:40:39.855277	testBot	1125	\N
15726	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:39.857598	testBot	1125	\N
15727	{"message":"Job (id=1125) executed successfully","level":2}	2019-12-07 20:40:39.861848	testBot	1125	\N
15728	{"message":"Job (id=1125) execution started","level":2}	2019-12-07 20:40:39.91409	testBot	1125	\N
15729	{"message":"Executing step 'step1'","level":2}	2019-12-07 20:40:39.915823	testBot	1125	\N
15730	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 20:40:39.925393	testBot	1125	\N
15731	{"message":"Executing step 'step2'","level":2}	2019-12-07 20:40:39.927553	testBot	1125	\N
15732	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:39.936787	testBot	1125	\N
15733	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 20:40:39.939006	testBot	1125	\N
15734	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:39.941079	testBot	1125	\N
15735	{"message":"Job (id=1125) executed successfully","level":2}	2019-12-07 20:40:39.944968	testBot	1125	\N
15736	{"message":"Job (id=1125) execution started","level":2}	2019-12-07 20:40:39.987326	testBot	1125	\N
15737	{"message":"Executing step 'step1'","level":2}	2019-12-07 20:40:39.988998	testBot	1125	\N
15738	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 20:40:39.997963	testBot	1125	\N
15739	{"message":"Executing step 'step2'","level":2}	2019-12-07 20:40:40.000132	testBot	1125	\N
15740	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:40.008536	testBot	1125	\N
15741	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 20:40:40.010854	testBot	1125	\N
15742	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 20:40:40.013328	testBot	1125	\N
15743	{"message":"Job (id=1125) executed successfully","level":2}	2019-12-07 20:40:40.017713	testBot	1125	\N
15744	{"message":"Job (id=1125) execution started","level":2}	2019-12-07 20:40:40.064821	testBot	1125	\N
15745	{"message":"Executing step 'step1'","level":2}	2019-12-07 20:40:40.066978	testBot	1125	\N
15746	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 20:40:40.078205	testBot	1125	\N
15747	{"message":"Executing step 'step2'","level":2}	2019-12-07 20:40:40.080812	testBot	1125	\N
15748	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:40.088047	testBot	1125	\N
15749	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 20:40:40.090191	testBot	1125	\N
15750	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 20:40:40.092421	testBot	1125	\N
15751	{"message":"Job (id=1125) executed successfully","level":2}	2019-12-07 20:40:40.096377	testBot	1125	\N
15752	{"message":"Job (id=1125) execution started","level":2}	2019-12-07 20:40:40.138172	testBot	1125	\N
15753	{"message":"Executing step 'step1'","level":2}	2019-12-07 20:40:40.140486	testBot	1125	\N
15754	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 20:40:40.150103	testBot	1125	\N
15755	{"message":"Executing step 'step2'","level":2}	2019-12-07 20:40:40.152112	testBot	1125	\N
15756	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:40.160611	testBot	1125	\N
15757	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 20:40:40.162951	testBot	1125	\N
15758	{"message":"Step 'step2' successfully executed after 1 attempt","level":2}	2019-12-07 20:40:40.164999	testBot	1125	\N
15759	{"message":"Job (id=1125) failed'","level":0}	2019-12-07 20:40:40.168954	testBot	1125	\N
15760	{"message":"Job (id=1125) execution started","level":2}	2019-12-07 20:40:40.212241	testBot	1125	\N
15761	{"message":"No any steps were found for job (id=1125)","level":0}	2019-12-07 20:40:40.214207	testBot	1125	\N
15762	{"message":"Job (id=1125) executed successfully","level":2}	2019-12-07 20:40:40.218487	testBot	1125	\N
15763	{"message":"Job (id=1125) execution started","level":2}	2019-12-07 20:40:40.245632	testBot	1125	\N
15764	{"message":"Executing step 'step1'","level":2}	2019-12-07 20:40:40.24855	testBot	1125	\N
15765	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-07 20:40:40.258	testBot	1125	\N
15766	{"message":"Executing step 'step2'","level":2}	2019-12-07 20:40:40.25999	testBot	1125	\N
15767	{"message":"Failed to execute step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:40.2685	testBot	1125	\N
15768	{"message":"Trying to repeat step 'step2'. Attempt 1 of 1","level":2}	2019-12-07 20:40:40.270784	testBot	1125	\N
15769	{"message":"1 repeat attempt failed for step 'step2'","error":"function fnLog_I2nsert(integer, unknown, unknown) does not exist","level":0}	2019-12-07 20:40:40.272854	testBot	1125	\N
15770	{"message":"Job (id=1125) failed'","level":0}	2019-12-07 20:40:40.27691	testBot	1125	\N
15771	{"message":"Job (id=1129) execution started","level":2}	2019-12-08 11:08:17.556745	testBot	1129	\N
15772	{"message":"Executing step 'step1'","level":2}	2019-12-08 11:08:17.567299	testBot	1129	\N
15773	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-08 11:08:17.582857	testBot	1129	\N
15774	{"message":"Job (id=1129) executed successfully","level":2}	2019-12-08 11:08:17.605887	testBot	1129	\N
15775	{"message":"Job (id=1130) execution started","level":2}	2019-12-08 11:10:14.769778	testBot	1130	\N
15776	{"message":"Executing step 'step1'","level":2}	2019-12-08 11:10:14.772756	testBot	1130	\N
15777	{"message":"Step 'step1' successfully executed","rowsAffected":1,"level":2}	2019-12-08 11:10:14.786215	testBot	1130	\N
15778	{"message":"Job (id=1130) executed successfully","level":2}	2019-12-08 11:10:14.797747	testBot	1130	\N
\.


--
-- TOC entry 2955 (class 0 OID 16444)
-- Dependencies: 204
-- Data for Name: tblLog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblLog" (id, type, message, "createdOn", "createdBy") FROM stdin;
4376	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 21:18:01.945762	\N
4377	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 21:18:01.950189	1
4378	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 21:21:52.316022	\N
4379	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 21:21:52.320108	1
4380	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 21:24:49.879583	\N
4381	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 21:24:49.886953	1
4382	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 21:25:03.909317	\N
4383	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 21:25:03.91434	1
4448	1	Potatoes!	2019-12-07 09:21:07.895226	test
4384	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 21:27:04.160353	\N
4385	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 21:27:04.1669	1
4386	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 22:22:33.438137	\N
4387	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-06 22:22:33.445281	1
4388	1	Potatoes!	2019-12-07 07:51:16.157787	test
4389	1	Potatoes!	2019-12-07 08:13:49.643297	test
4390	1	Potatoes!	2019-12-07 08:14:59.55866	test
4391	1	Potatoes!	2019-12-07 08:15:42.744761	test
4392	1	Potatoes!	2019-12-07 08:15:57.28819	test
4393	1	Potatoes!	2019-12-07 08:17:15.647849	test
4394	1	Potatoes!	2019-12-07 08:18:03.522341	test
4395	1	Potatoes!	2019-12-07 08:19:46.347768	test
4396	1	Potatoes!	2019-12-07 08:19:47.483364	test
4397	1	Potatoes!	2019-12-07 08:22:39.027309	test
4398	1	Potatoes!	2019-12-07 08:22:39.146496	test
4399	1	Potatoes!	2019-12-07 08:24:18.188675	test
4400	1	Potatoes!	2019-12-07 08:24:18.300656	test
4401	1	Potatoes!	2019-12-07 08:24:58.500623	test
4402	1	Potatoes!	2019-12-07 08:34:02.973575	test
4403	1	Potatoes!	2019-12-07 08:34:03.094363	test
4404	1	Potatoes!	2019-12-07 08:34:12.293146	test
4405	1	Potatoes!	2019-12-07 08:34:12.409883	test
4406	1	Potatoes!	2019-12-07 08:35:16.776973	test
4407	1	Potatoes!	2019-12-07 08:35:16.903995	test
4408	1	Potatoes!	2019-12-07 08:35:16.973169	test
4409	1	Potatoes!	2019-12-07 08:36:47.255764	test
4410	1	Potatoes!	2019-12-07 08:36:47.354898	test
4411	1	Potatoes!	2019-12-07 08:36:47.423322	test
4412	1	Potatoes!	2019-12-07 08:40:12.469895	test
4413	1	Potatoes!	2019-12-07 08:40:12.568284	test
4414	1	Potatoes!	2019-12-07 08:40:12.636324	test
4415	1	Potatoes!	2019-12-07 08:40:12.719813	test
4416	1	Potatoes!	2019-12-07 08:40:12.817022	test
4417	1	Potatoes!	2019-12-07 08:42:14.907847	test
4418	1	Potatoes!	2019-12-07 08:42:15.013807	test
4419	1	Potatoes!	2019-12-07 08:42:15.083535	test
4420	1	Potatoes!	2019-12-07 08:42:15.165724	test
4421	1	Potatoes!	2019-12-07 08:42:15.246678	test
4422	1	Potatoes!	2019-12-07 09:05:57.884994	test
4423	1	Potatoes!	2019-12-07 09:05:57.995201	test
4424	1	Potatoes!	2019-12-07 09:05:58.084875	test
4425	1	Potatoes!	2019-12-07 09:05:58.165397	test
4426	1	Potatoes!	2019-12-07 09:05:58.236839	test
4427	1	Potatoes!	2019-12-07 09:05:58.311124	test
4428	1	Potatoes!	2019-12-07 09:07:08.522205	test
4429	1	Potatoes!	2019-12-07 09:07:08.61932	test
4430	1	Potatoes!	2019-12-07 09:07:08.685949	test
4431	1	Potatoes!	2019-12-07 09:07:08.777502	test
4432	1	Potatoes!	2019-12-07 09:07:08.859667	test
4433	1	Potatoes!	2019-12-07 09:07:08.934366	test
4434	1	Potatoes!	2019-12-07 09:19:24.004278	test
4435	1	Potatoes!	2019-12-07 09:19:24.131413	test
4436	1	Potatoes!	2019-12-07 09:19:24.195686	test
4437	1	Potatoes!	2019-12-07 09:19:24.271581	test
4438	1	Potatoes!	2019-12-07 09:19:24.358223	test
4439	1	Potatoes!	2019-12-07 09:19:24.435953	test
4440	1	Potatoes!	2019-12-07 09:20:55.722668	test
4441	1	Potatoes!	2019-12-07 09:20:55.817371	test
4442	1	Potatoes!	2019-12-07 09:20:55.889459	test
4443	1	Potatoes!	2019-12-07 09:20:55.968087	test
4444	1	Potatoes!	2019-12-07 09:20:56.048209	test
4445	1	Potatoes!	2019-12-07 09:20:56.135008	test
4446	1	Potatoes!	2019-12-07 09:20:56.204991	test
4447	1	Potatoes!	2019-12-07 09:20:56.268179	test
4449	1	Potatoes!	2019-12-07 09:21:07.996299	test
4450	1	Potatoes!	2019-12-07 09:21:08.073477	test
4451	1	Potatoes!	2019-12-07 09:21:08.168216	test
4452	1	Potatoes!	2019-12-07 09:21:08.251544	test
4453	1	Potatoes!	2019-12-07 09:21:08.331766	test
4454	1	Potatoes!	2019-12-07 09:21:08.404096	test
4455	1	Potatoes!	2019-12-07 09:21:08.490997	test
4456	1	Potatoes!	2019-12-07 09:29:10.823508	test
4457	1	Potatoes!	2019-12-07 09:29:10.920988	test
4458	1	Potatoes!	2019-12-07 09:29:10.989632	test
4459	1	Potatoes!	2019-12-07 09:29:11.079859	test
4460	1	Potatoes!	2019-12-07 09:29:11.162175	test
4461	1	Potatoes!	2019-12-07 09:29:11.237467	test
4462	1	Potatoes!	2019-12-07 09:29:11.309581	test
4463	1	Potatoes!	2019-12-07 09:29:11.383126	test
4464	1	Potatoes!	2019-12-07 09:29:41.81729	test
4465	1	Potatoes!	2019-12-07 09:29:41.917903	test
4466	1	Potatoes!	2019-12-07 09:29:41.989126	test
4467	1	Potatoes!	2019-12-07 09:29:42.076749	test
4468	1	Potatoes!	2019-12-07 09:29:42.157351	test
4469	1	Potatoes!	2019-12-07 09:29:42.239536	test
4470	1	Potatoes!	2019-12-07 09:29:42.314605	test
4471	1	Potatoes!	2019-12-07 09:29:42.392114	test
4472	1	Potatoes!	2019-12-07 09:31:16.70959	test
4473	1	Potatoes!	2019-12-07 09:31:16.810852	test
4474	1	Potatoes!	2019-12-07 09:31:16.879966	test
4475	1	Potatoes!	2019-12-07 09:31:16.96403	test
4476	1	Potatoes!	2019-12-07 09:31:17.048998	test
4477	1	Potatoes!	2019-12-07 09:31:17.124593	test
4478	1	Potatoes!	2019-12-07 09:31:17.202327	test
4479	1	Potatoes!	2019-12-07 09:31:17.288497	test
4480	1	Potatoes!	2019-12-07 09:31:30.540838	test
4481	1	Potatoes!	2019-12-07 09:31:30.641459	test
4482	1	Potatoes!	2019-12-07 09:31:30.715284	test
4483	1	Potatoes!	2019-12-07 09:31:30.800433	test
4484	1	Potatoes!	2019-12-07 09:31:30.891738	test
4485	1	Potatoes!	2019-12-07 09:31:30.964782	test
4486	1	Potatoes!	2019-12-07 09:31:31.042265	test
4487	1	Potatoes!	2019-12-07 09:31:31.119781	test
4488	1	Potatoes!	2019-12-07 09:33:00.588107	test
4489	1	Potatoes!	2019-12-07 09:33:00.683727	test
4490	1	Potatoes!	2019-12-07 09:33:00.757067	test
4491	1	Potatoes!	2019-12-07 09:33:00.843967	test
4492	1	Potatoes!	2019-12-07 09:33:00.919733	test
4493	1	Potatoes!	2019-12-07 09:33:00.993836	test
4494	1	Potatoes!	2019-12-07 09:33:01.06553	test
4495	1	Potatoes!	2019-12-07 09:33:01.143809	test
4496	1	Potatoes!	2019-12-07 09:33:27.354005	test
4497	1	Potatoes!	2019-12-07 09:33:27.448831	test
4498	1	Potatoes!	2019-12-07 09:33:27.513146	test
4499	1	Potatoes!	2019-12-07 09:33:27.589386	test
4500	1	Potatoes!	2019-12-07 09:33:27.667616	test
4501	1	Potatoes!	2019-12-07 09:33:27.744588	test
4502	1	Potatoes!	2019-12-07 09:33:27.824498	test
4503	1	Potatoes!	2019-12-07 09:33:27.89431	test
4504	1	Potatoes!	2019-12-07 09:34:26.070216	test
4505	1	Potatoes!	2019-12-07 09:34:26.168857	test
4506	1	Potatoes!	2019-12-07 09:34:26.236674	test
4507	1	Potatoes!	2019-12-07 09:34:26.319832	test
4508	1	Potatoes!	2019-12-07 09:34:26.410672	test
4509	1	Potatoes!	2019-12-07 09:34:26.498439	test
4510	1	Potatoes!	2019-12-07 09:34:26.581383	test
4511	1	Potatoes!	2019-12-07 09:34:26.653893	test
4512	1	Potatoes!	2019-12-07 09:35:02.936135	test
4513	1	Potatoes!	2019-12-07 09:35:03.032473	test
4514	1	Potatoes!	2019-12-07 09:35:03.096714	test
4515	1	Potatoes!	2019-12-07 09:35:03.192168	test
4516	1	Potatoes!	2019-12-07 09:35:03.271713	test
4517	1	Potatoes!	2019-12-07 09:35:03.347176	test
4518	1	Potatoes!	2019-12-07 09:35:03.421881	test
4519	1	Potatoes!	2019-12-07 09:35:03.496462	test
4520	1	Potatoes!	2019-12-07 09:36:49.686725	test
4521	1	Potatoes!	2019-12-07 09:36:49.788379	test
4522	1	Potatoes!	2019-12-07 09:36:49.867889	test
4523	1	Potatoes!	2019-12-07 09:36:49.948612	test
4524	1	Potatoes!	2019-12-07 09:36:50.042716	test
4525	1	Potatoes!	2019-12-07 09:36:50.128386	test
4526	1	Potatoes!	2019-12-07 09:36:50.20999	test
4527	1	Potatoes!	2019-12-07 09:36:50.284073	test
4528	1	Potatoes!	2019-12-07 09:38:03.934746	test
4529	1	Potatoes!	2019-12-07 09:38:04.055137	test
4530	1	Potatoes!	2019-12-07 09:38:04.128571	test
4531	1	Potatoes!	2019-12-07 09:38:04.210004	test
4532	1	Potatoes!	2019-12-07 09:38:04.293805	test
4533	1	Potatoes!	2019-12-07 09:38:04.380989	test
4534	1	Potatoes!	2019-12-07 09:38:04.462173	test
4535	1	Potatoes!	2019-12-07 09:38:04.537307	test
4536	1	Potatoes!	2019-12-07 09:39:02.740781	test
4537	1	Potatoes!	2019-12-07 09:39:02.838098	test
4538	1	Potatoes!	2019-12-07 09:39:02.913612	test
4539	1	Potatoes!	2019-12-07 09:39:03.001994	test
4540	1	Potatoes!	2019-12-07 09:39:03.077702	test
4541	1	Potatoes!	2019-12-07 09:39:03.159289	test
4542	1	Potatoes!	2019-12-07 09:39:03.237777	test
4543	1	Potatoes!	2019-12-07 09:39:03.321692	test
4544	1	Potatoes!	2019-12-07 09:39:50.047222	test
4545	1	Potatoes!	2019-12-07 09:39:50.148746	test
4546	1	Potatoes!	2019-12-07 09:39:50.218904	test
4547	1	Potatoes!	2019-12-07 09:39:50.299504	test
4548	1	Potatoes!	2019-12-07 09:39:50.371372	test
4549	1	Potatoes!	2019-12-07 09:39:50.449124	test
4550	1	Potatoes!	2019-12-07 09:39:50.525185	test
4551	1	Potatoes!	2019-12-07 09:39:50.599149	test
4552	1	Potatoes!	2019-12-07 09:40:07.499577	test
4553	1	Potatoes!	2019-12-07 09:40:07.60693	test
4554	1	Potatoes!	2019-12-07 09:40:07.679322	test
4555	1	Potatoes!	2019-12-07 09:40:07.766437	test
4556	1	Potatoes!	2019-12-07 09:40:07.84698	test
4557	1	Potatoes!	2019-12-07 09:40:07.926723	test
4558	1	Potatoes!	2019-12-07 09:40:07.999386	test
4559	1	Potatoes!	2019-12-07 09:40:08.067961	test
4560	1	Potatoes!	2019-12-07 09:40:53.422352	test
4561	1	Potatoes!	2019-12-07 09:40:53.52332	test
4562	1	Potatoes!	2019-12-07 09:40:53.602215	test
4563	1	Potatoes!	2019-12-07 09:40:53.682044	test
4564	1	Potatoes!	2019-12-07 09:40:53.772397	test
4565	1	Potatoes!	2019-12-07 09:40:53.855438	test
4566	1	Potatoes!	2019-12-07 09:40:53.928076	test
4567	1	Potatoes!	2019-12-07 09:40:54.00259	test
4568	1	Potatoes!	2019-12-07 09:42:04.033191	test
4569	1	Potatoes!	2019-12-07 09:42:04.138278	test
4570	1	Potatoes!	2019-12-07 09:42:04.217506	test
4571	1	Potatoes!	2019-12-07 09:42:04.299884	test
4572	1	Potatoes!	2019-12-07 09:42:04.373778	test
4573	1	Potatoes!	2019-12-07 09:42:04.449952	test
4574	1	Potatoes!	2019-12-07 09:42:04.528121	test
4575	1	Potatoes!	2019-12-07 09:42:04.600726	test
4576	1	Potatoes!	2019-12-07 09:43:22.592176	test
4577	1	Potatoes!	2019-12-07 09:43:22.687389	test
4578	1	Potatoes!	2019-12-07 09:43:22.756681	test
4579	1	Potatoes!	2019-12-07 09:43:22.844816	test
4580	1	Potatoes!	2019-12-07 09:43:22.917097	test
4581	1	Potatoes!	2019-12-07 09:43:22.994209	test
4582	1	Potatoes!	2019-12-07 09:43:23.063416	test
4583	1	Potatoes!	2019-12-07 09:43:23.132838	test
4584	1	Potatoes!	2019-12-07 09:46:30.721237	test
4585	1	Potatoes!	2019-12-07 09:46:30.816191	test
4586	1	Potatoes!	2019-12-07 09:46:30.88382	test
4587	1	Potatoes!	2019-12-07 09:46:30.960663	test
4588	1	Potatoes!	2019-12-07 09:46:31.040271	test
4589	1	Potatoes!	2019-12-07 09:46:31.1225	test
4590	1	Potatoes!	2019-12-07 09:46:31.202283	test
4591	1	Potatoes!	2019-12-07 09:46:31.27544	test
4592	1	Potatoes!	2019-12-07 09:48:53.729727	test
4593	1	Potatoes!	2019-12-07 09:48:53.824577	test
4594	1	Potatoes!	2019-12-07 09:48:53.893539	test
4595	1	Potatoes!	2019-12-07 09:48:53.994769	test
4596	1	Potatoes!	2019-12-07 09:48:54.076607	test
4597	1	Potatoes!	2019-12-07 09:48:54.14889	test
4598	1	Potatoes!	2019-12-07 09:48:54.229912	test
4599	1	Potatoes!	2019-12-07 09:48:54.304644	test
4600	1	Potatoes!	2019-12-07 09:50:51.671872	test
4601	1	Potatoes!	2019-12-07 09:50:51.76394	test
4602	1	Potatoes!	2019-12-07 09:50:51.832211	test
4603	1	Potatoes!	2019-12-07 09:50:51.908092	test
4604	1	Potatoes!	2019-12-07 09:50:51.987579	test
4605	1	Potatoes!	2019-12-07 09:50:52.072401	test
4606	1	Potatoes!	2019-12-07 09:50:52.145737	test
4607	1	Potatoes!	2019-12-07 09:50:52.222003	test
4608	1	Potatoes!	2019-12-07 09:51:40.431065	test
4609	1	Potatoes!	2019-12-07 09:51:40.532092	test
4610	1	Potatoes!	2019-12-07 09:51:40.611496	test
4611	1	Potatoes!	2019-12-07 09:51:40.697066	test
4612	1	Potatoes!	2019-12-07 09:51:40.782112	test
4613	1	Potatoes!	2019-12-07 09:51:40.855912	test
4614	1	Potatoes!	2019-12-07 09:51:40.933014	test
4615	1	Potatoes!	2019-12-07 09:51:41.014905	test
4616	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 09:51:41.171675	\N
4617	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 09:51:41.175784	1
4618	1	Potatoes!	2019-12-07 09:53:19.341596	test
4619	1	Potatoes!	2019-12-07 09:53:19.433543	test
4620	1	Potatoes!	2019-12-07 09:53:19.501347	test
4621	1	Potatoes!	2019-12-07 09:53:19.584179	test
4622	1	Potatoes!	2019-12-07 09:53:19.671271	test
4623	1	Potatoes!	2019-12-07 09:53:19.740139	test
4624	1	Potatoes!	2019-12-07 09:53:19.811393	test
4625	1	Potatoes!	2019-12-07 09:53:19.880761	test
4626	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 09:53:20.042835	\N
4627	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 09:53:20.046159	1
4628	1	Potatoes!	2019-12-07 09:55:23.041161	test
4629	1	Potatoes!	2019-12-07 09:55:23.15179	test
4630	1	Potatoes!	2019-12-07 09:55:23.231369	test
4631	1	Potatoes!	2019-12-07 09:55:23.309534	test
4632	1	Potatoes!	2019-12-07 09:55:23.387628	test
4633	1	Potatoes!	2019-12-07 09:55:23.466676	test
4634	1	Potatoes!	2019-12-07 09:55:23.553947	test
4635	1	Potatoes!	2019-12-07 09:55:23.625277	test
4636	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 09:55:23.780586	\N
4637	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 09:55:23.784226	1
4638	1	Potatoes!	2019-12-07 09:59:08.719092	test
4639	1	Potatoes!	2019-12-07 09:59:08.81992	test
4640	1	Potatoes!	2019-12-07 09:59:08.885569	test
4641	1	Potatoes!	2019-12-07 09:59:08.969357	test
4642	1	Potatoes!	2019-12-07 09:59:09.055322	test
4643	1	Potatoes!	2019-12-07 09:59:09.130088	test
4644	1	Potatoes!	2019-12-07 09:59:09.204716	test
4645	1	Potatoes!	2019-12-07 09:59:09.281702	test
4646	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 09:59:09.44749	\N
4647	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 09:59:09.451648	1
4648	1	Potatoes!	2019-12-07 10:00:22.460555	test
4649	1	Potatoes!	2019-12-07 10:00:22.561323	test
4650	1	Potatoes!	2019-12-07 10:00:22.630573	test
4651	1	Potatoes!	2019-12-07 10:00:22.710556	test
4652	1	Potatoes!	2019-12-07 10:00:22.785825	test
4653	1	Potatoes!	2019-12-07 10:00:22.872717	test
4654	1	Potatoes!	2019-12-07 10:00:22.945239	test
4655	1	Potatoes!	2019-12-07 10:00:23.022239	test
4656	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:00:23.198898	\N
4657	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:00:23.202645	1
4658	1	Potatoes!	2019-12-07 10:01:37.103904	test
4659	1	Potatoes!	2019-12-07 10:01:37.205267	test
4660	1	Potatoes!	2019-12-07 10:01:37.275385	test
4661	1	Potatoes!	2019-12-07 10:01:37.35922	test
4662	1	Potatoes!	2019-12-07 10:01:37.434154	test
4663	1	Potatoes!	2019-12-07 10:01:37.519278	test
4664	1	Potatoes!	2019-12-07 10:01:37.59948	test
4665	1	Potatoes!	2019-12-07 10:01:37.680133	test
4666	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:01:37.847922	\N
4667	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:01:37.85182	1
4668	1	Potatoes!	2019-12-07 10:02:32.814908	test
4669	1	Potatoes!	2019-12-07 10:02:32.907937	test
4670	1	Potatoes!	2019-12-07 10:02:32.977221	test
4671	1	Potatoes!	2019-12-07 10:02:33.060227	test
4672	1	Potatoes!	2019-12-07 10:02:33.140335	test
4673	1	Potatoes!	2019-12-07 10:02:33.226169	test
4674	1	Potatoes!	2019-12-07 10:02:33.303357	test
4675	1	Potatoes!	2019-12-07 10:02:33.382188	test
4676	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:02:33.562142	\N
4677	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:02:33.570725	1
4678	1	Potatoes!	2019-12-07 10:05:41.07371	test
4679	1	Potatoes!	2019-12-07 10:05:41.174856	test
4680	1	Potatoes!	2019-12-07 10:05:41.255738	test
4681	1	Potatoes!	2019-12-07 10:05:41.331777	test
4682	1	Potatoes!	2019-12-07 10:05:41.408176	test
4683	1	Potatoes!	2019-12-07 10:05:41.483767	test
4684	1	Potatoes!	2019-12-07 10:05:41.560563	test
4685	1	Potatoes!	2019-12-07 10:05:41.632095	test
4686	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:05:41.809255	\N
4687	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:05:41.812646	1
4688	1	Potatoes!	2019-12-07 10:08:53.359003	test
4689	1	Potatoes!	2019-12-07 10:08:53.472563	test
4690	1	Potatoes!	2019-12-07 10:08:53.544937	test
4691	1	Potatoes!	2019-12-07 10:08:53.636307	test
4692	1	Potatoes!	2019-12-07 10:08:53.728912	test
4693	1	Potatoes!	2019-12-07 10:08:53.808701	test
4694	1	Potatoes!	2019-12-07 10:08:53.88144	test
4695	1	Potatoes!	2019-12-07 10:08:53.9737	test
4696	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:08:54.149363	\N
4697	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:08:54.152847	1
4698	1	Potatoes!	2019-12-07 10:15:28.460907	test
4699	1	Potatoes!	2019-12-07 10:15:28.553959	test
4700	1	Potatoes!	2019-12-07 10:15:28.620964	test
4701	1	Potatoes!	2019-12-07 10:15:28.694709	test
4702	1	Potatoes!	2019-12-07 10:15:28.775052	test
4703	1	Potatoes!	2019-12-07 10:15:28.858651	test
4704	1	Potatoes!	2019-12-07 10:15:28.931083	test
4705	1	Potatoes!	2019-12-07 10:15:29.005087	test
4706	1	Potatoes!	2019-12-07 10:15:29.112004	test
4707	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:15:30.26529	\N
4708	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:15:30.270741	1
4709	1	Potatoes!	2019-12-07 10:16:22.092435	test
4710	1	Potatoes!	2019-12-07 10:16:22.192758	test
4711	1	Potatoes!	2019-12-07 10:16:22.280894	test
4712	1	Potatoes!	2019-12-07 10:16:22.358805	test
4713	1	Potatoes!	2019-12-07 10:16:22.434411	test
4714	1	Potatoes!	2019-12-07 10:16:22.509612	test
4715	1	Potatoes!	2019-12-07 10:16:22.584651	test
4716	1	Potatoes!	2019-12-07 10:16:22.661429	test
4717	1	Potatoes!	2019-12-07 10:16:22.76832	test
4718	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:16:22.904856	\N
4719	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 10:16:22.90816	1
4720	1	Potatoes!	2019-12-07 20:40:39.566855	test
4721	1	Potatoes!	2019-12-07 20:40:39.681439	test
4722	1	Potatoes!	2019-12-07 20:40:39.757179	test
4723	1	Potatoes!	2019-12-07 20:40:39.83737	test
4724	1	Potatoes!	2019-12-07 20:40:39.922644	test
4725	1	Potatoes!	2019-12-07 20:40:39.995215	test
4726	1	Potatoes!	2019-12-07 20:40:40.075324	test
4727	1	Potatoes!	2019-12-07 20:40:40.147353	test
4728	1	Potatoes!	2019-12-07 20:40:40.255008	test
4729	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:42:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 20:40:40.377342	\N
4730	1	{"type":"Error","message":"dummy","name":"Error","stack":"Error: dummy\\n    at Context.<anonymous> (/home/major/_code/peon/test/misc/tools_tests.js:46:45)\\n    at callFn (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:372:21)\\n    at Test.Runnable.run (/home/major/_code/peon/node_modules/mocha/lib/runnable.js:364:7)\\n    at Runner.runTest (/home/major/_code/peon/node_modules/mocha/lib/runner.js:455:10)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:573:12\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:369:14)\\n    at /home/major/_code/peon/node_modules/mocha/lib/runner.js:379:7\\n    at next (/home/major/_code/peon/node_modules/mocha/lib/runner.js:303:14)\\n    at Immediate.<anonymous> (/home/major/_code/peon/node_modules/mocha/lib/runner.js:347:5)\\n    at runCallback (timers.js:794:20)\\n    at tryOnImmediate (timers.js:752:5)\\n    at processImmediate [as _immediateCallback] (timers.js:729:5)"}	2019-12-07 20:40:40.380934	1
4731	1	Potatoes!	2019-12-08 11:08:17.579518	test
4732	1	Potatoes!	2019-12-08 11:10:14.782652	test
\.


--
-- TOC entry 2957 (class 0 OID 16453)
-- Dependencies: 206
-- Data for Name: tblRunHistory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblRunHistory" (id, message, "createdOn", "createdBy", session) FROM stdin;
7793	Starting execution of job (id=600)	2019-10-08 18:35:00.225311	system	3bd3b147-9d32-47e9-8759-75d0f65cdf22
7794	Starting execution of job (id=600)	2019-10-08 18:40:00.562759	system	e724da05-4a82-454b-a322-3d4a4105eea4
7795	Starting execution of job (id=600)	2019-10-08 18:45:33.642693	system	d6464593-75d5-4235-ae94-9b25a2f673c7
7796	Starting execution of job (id=719)	2019-12-02 18:05:00.667788	system	be1318df-4c48-418f-b2ee-9f2981eff957
7797	Starting execution of job (id=719)	2019-12-02 18:10:00.000786	system	5295a3ef-da06-4ebd-86e6-784c2ce897fa
7798	Starting execution of job (id=720)	2019-12-02 18:10:00.012211	system	5295a3ef-da06-4ebd-86e6-784c2ce897fa
7799	Starting execution of job (id=721)	2019-12-02 18:10:00.022466	system	5295a3ef-da06-4ebd-86e6-784c2ce897fa
7800	Starting execution of job (id=719)	2019-12-02 18:15:43.935596	system	e769735c-e9dc-4454-8536-26c0310c6949
7801	Starting execution of job (id=720)	2019-12-02 18:15:43.953112	system	e769735c-e9dc-4454-8536-26c0310c6949
7802	Starting execution of job (id=721)	2019-12-02 18:15:43.964069	system	e769735c-e9dc-4454-8536-26c0310c6949
7803	Starting execution of job (id=728)	2019-12-02 18:20:00.216766	system	d569eaa4-8b7a-4869-8f7a-65d010216f48
7804	Starting execution of job (id=731)	2019-12-02 18:20:00.238435	system	d569eaa4-8b7a-4869-8f7a-65d010216f48
7805	Starting execution of job (id=732)	2019-12-02 18:20:00.250664	system	d569eaa4-8b7a-4869-8f7a-65d010216f48
7806	Starting execution of job (id=733)	2019-12-02 18:20:00.257197	system	d569eaa4-8b7a-4869-8f7a-65d010216f48
7807	Starting execution of job (id=734)	2019-12-02 18:20:00.267107	system	d569eaa4-8b7a-4869-8f7a-65d010216f48
7808	Starting execution of job (id=735)	2019-12-02 18:20:00.271308	system	d569eaa4-8b7a-4869-8f7a-65d010216f48
7809	Starting execution of job (id=736)	2019-12-02 18:20:00.288331	system	d569eaa4-8b7a-4869-8f7a-65d010216f48
7810	Starting execution of job (id=737)	2019-12-02 18:20:00.298695	system	d569eaa4-8b7a-4869-8f7a-65d010216f48
7811	Starting execution of job (id=738)	2019-12-02 18:20:00.316816	system	d569eaa4-8b7a-4869-8f7a-65d010216f48
7812	Starting execution of job (id=741)	2019-12-02 18:30:00.531294	system	3ab743ab-dbe7-4509-9ac7-2e9c381c4b5a
7813	Starting execution of job (id=741)	2019-12-02 18:40:00.675511	system	913c485c-ef4a-49c0-80e1-5b8b760b9cc8
7814	Starting execution of job (id=741)	2019-12-02 18:40:01.676152	system	5c35ccff-1954-47ed-ad5c-4104142be31d
7815	Starting execution of job (id=741)	2019-12-02 18:40:02.675655	system	17670912-ac79-4e32-8e6e-81633a43913c
7816	Starting execution of job (id=741)	2019-12-02 18:40:03.677146	system	e73168de-186c-43b6-b074-852ca248c895
7817	Starting execution of job (id=741)	2019-12-02 18:40:04.677411	system	3fc33b42-4125-428b-a850-d72e28bff9a4
7818	Starting execution of job (id=741)	2019-12-02 18:40:05.677994	system	6825a5a4-2986-4cf9-80b1-6412b0d2a755
7819	Starting execution of job (id=741)	2019-12-02 18:40:06.678833	system	be2c6b46-02ed-44b4-b8aa-d7ba554f2f05
7820	Starting execution of job (id=741)	2019-12-02 18:40:07.680032	system	ee9cc9f8-14aa-4a42-83f5-e3880a1054ec
7821	Starting execution of job (id=741)	2019-12-02 18:40:08.68095	system	1364e9b9-346f-4514-96d5-cc5ce98b684f
7822	Starting execution of job (id=741)	2019-12-02 18:40:09.682541	system	96862f0c-a287-46f1-b5f4-2bb004592e94
7823	Starting execution of job (id=741)	2019-12-02 18:40:10.68433	system	ffde46ea-da0a-4035-be32-f41734d71c9e
7824	Starting execution of job (id=741)	2019-12-02 18:40:11.685007	system	d61a14c4-fe33-49aa-9243-335a9e866ebe
7825	Starting execution of job (id=741)	2019-12-02 18:40:12.686213	system	6ae0ad78-a5ef-4297-bbf8-5924da47ef07
7826	Starting execution of job (id=741)	2019-12-02 18:40:13.686258	system	5c44caef-9e37-4641-a4b7-c3a54fab21c1
7827	Starting execution of job (id=741)	2019-12-02 18:40:14.687041	system	7420bff4-2af1-432b-9bdd-da8bb3cedbb4
7828	Starting execution of job (id=741)	2019-12-02 18:40:15.68836	system	8dbf5e35-7f78-4a43-b373-ce54fa64f00f
7829	Starting execution of job (id=741)	2019-12-02 18:40:16.689263	system	1cc03b41-9eda-4b6c-85d6-c3704795caeb
7830	Starting execution of job (id=741)	2019-12-02 18:40:17.688454	system	aef20216-4877-41e3-b172-2d806b8ffc1e
7831	Starting execution of job (id=741)	2019-12-02 18:40:18.688688	system	a61e9e08-6d29-45ac-b28e-5b7d9d5aa69d
7832	Starting execution of job (id=741)	2019-12-02 18:40:19.691823	system	a956cec7-c99e-4e00-bc35-f809636ff986
7833	Starting execution of job (id=741)	2019-12-02 18:40:20.692932	system	73d87c9b-1abc-4761-b153-65e7f41ceb46
7834	Starting execution of job (id=741)	2019-12-02 18:40:21.693433	system	fa51a8e5-fab3-4499-b726-253d56b7ff50
7835	Starting execution of job (id=741)	2019-12-02 18:40:22.694646	system	12cf1f5d-ae58-4729-aa46-80f288af13db
7836	Starting execution of job (id=741)	2019-12-02 18:40:23.693632	system	98a84b85-90fe-446e-b15c-90d2c14b558b
7837	Starting execution of job (id=741)	2019-12-02 18:40:24.696965	system	04e2e239-dd7a-4e82-8fe0-3fb8fa78a0f7
7838	Starting execution of job (id=741)	2019-12-02 18:40:25.697728	system	16411dd5-6744-47f2-bdaa-9d392159432d
7839	Starting execution of job (id=741)	2019-12-02 18:40:26.696752	system	3a4dec90-bdad-4f30-8876-5ace7dfc70b8
7840	Starting execution of job (id=741)	2019-12-02 18:40:27.700366	system	73538506-4901-46ef-8606-1a7fbacc7a75
7841	Starting execution of job (id=741)	2019-12-02 18:40:28.700505	system	444caed3-d486-40c8-8aea-0dcd2bda5803
7842	Starting execution of job (id=741)	2019-12-02 18:40:29.701821	system	fd588dd2-63a5-46ae-8b95-d2b1c198caf2
7843	Starting execution of job (id=741)	2019-12-02 18:40:30.702581	system	2fef127b-442a-42f8-af66-e8e2566e606b
7844	Starting execution of job (id=741)	2019-12-02 18:43:00.31072	system	79187b16-ca63-4405-b6ec-fcc0d5a16bb3
7845	Starting execution of job (id=741)	2019-12-02 18:43:01.311866	system	b9f600fe-acb9-4c19-ab31-5d010f2d6afe
7846	Starting execution of job (id=741)	2019-12-02 18:43:02.312448	system	9d5f16fb-9f90-4350-815d-5172675c1609
7847	Starting execution of job (id=741)	2019-12-02 18:43:03.312449	system	bf2872da-e5c2-4918-93b4-db1ad32d6171
7848	Starting execution of job (id=741)	2019-12-02 18:43:04.310543	system	3b721495-edaf-493c-8607-337d19d4ef6e
7849	Starting execution of job (id=741)	2019-12-02 18:43:05.314103	system	70b5d1ba-ab19-4829-bdf0-066b863f9bb6
7850	Starting execution of job (id=741)	2019-12-02 18:43:06.315812	system	47f25e22-ab4a-408f-a035-e6ac886e5bd4
7851	Starting execution of job (id=741)	2019-12-02 18:43:07.316334	system	b2d55580-6cc6-4306-89c7-d5703048062e
7852	Starting execution of job (id=741)	2019-12-02 18:43:08.317316	system	4e9bbb25-ed86-4c51-93b2-1296f415c7e5
7853	Starting execution of job (id=741)	2019-12-02 18:43:09.319009	system	80a64b15-d606-4917-941c-78904fc5615e
7854	Starting execution of job (id=741)	2019-12-02 18:43:10.319715	system	03f6ca6d-5a5e-40b6-9c4f-d80e46e7210c
7855	Starting execution of job (id=741)	2019-12-02 18:43:11.32149	system	8c0208c9-881d-4a66-b2a7-d58431479ded
7856	Starting execution of job (id=741)	2019-12-02 18:43:12.320882	system	c46be704-05ea-4287-93ad-323803033839
7857	Starting execution of job (id=741)	2019-12-02 18:43:13.324147	system	0edcc27b-81c7-4689-a111-ab938fee6485
7858	Starting execution of job (id=741)	2019-12-02 18:43:14.322451	system	4645e7c5-65e6-42ea-8e6a-49937720fc45
7859	Starting execution of job (id=741)	2019-12-02 18:52:00.740532	system	06be96f8-fb72-4b29-94e6-46dd149d9f7a
7860	Starting execution of job (id=741)	2019-12-02 18:56:00.822369	system	71ca9379-88c5-4564-bbb0-5e0ee511796a
7861	Starting execution of job (id=741)	2019-12-02 18:59:00.750678	system	7ffd1d08-5194-4ff7-a736-a432cf288d1e
7862	Starting execution of job (id=741)	2019-12-02 18:59:01.751855	system	6bcb0814-75f3-42d8-a350-8ad72ade1e5f
7863	Starting execution of job (id=741)	2019-12-02 18:59:02.751629	system	576cbc6f-a54b-4c11-b971-bb221f09ea87
7864	Starting execution of job (id=741)	2019-12-02 18:59:03.753182	system	59677eed-2370-429b-8a63-e84899f2b3d9
7865	Starting execution of job (id=741)	2019-12-02 18:59:04.753864	system	8dead159-4c32-43a1-92f4-49aa86edf237
7866	Starting execution of job (id=741)	2019-12-02 18:59:05.755408	system	66961077-6cda-4378-9cd8-e35f93a95c58
7867	Starting execution of job (id=741)	2019-12-02 18:59:06.75629	system	11857e61-f225-47e7-a5c3-a91b339217eb
7868	Starting execution of job (id=741)	2019-12-02 18:59:07.757722	system	3508c295-4e75-4283-8f59-c0edd879fa78
7869	Starting execution of job (id=741)	2019-12-02 18:59:08.758447	system	4a3493b9-82ad-4201-a448-520dd9f5410e
7870	Starting execution of job (id=741)	2019-12-02 18:59:09.758771	system	c4132e4b-9d6e-4011-a556-5893863b27d5
7871	Starting execution of job (id=741)	2019-12-02 18:59:10.760415	system	f5788233-2930-459e-bc3e-eefcac3e28c9
7872	Starting execution of job (id=741)	2019-12-02 18:59:11.761602	system	b4e9af15-0115-4a35-b301-7f80513da031
7873	Starting execution of job (id=741)	2019-12-02 18:59:12.763388	system	8907fd23-e64a-4573-b79d-5f7dab622e13
7874	Starting execution of job (id=741)	2019-12-02 18:59:13.763474	system	1d0d54a2-a43f-4340-93e1-9ba5cf13acff
7876	Starting execution of job (id=741)	2019-12-02 18:59:15.763061	system	08d6d6fb-34eb-4b00-a232-b2cefb766176
7875	Starting execution of job (id=741)	2019-12-02 18:59:14.764571	system	8622d77a-821f-40a3-b8fe-e091bf94a66b
7877	Starting execution of job (id=741)	2019-12-02 19:00:01.832987	system	7b45c007-a6ea-4559-b281-fbe014a57105
7878	Starting execution of job (id=741)	2019-12-02 19:01:00.527033	system	bc8e786a-0fb3-40ec-a1a7-1c3608bb5b75
7879	Starting execution of job (id=741)	2019-12-02 19:05:00.691074	system	c0e05505-2b19-4ce1-ab93-817fbf064e46
7880	Starting execution of job (id=741)	2019-12-02 19:09:00.254915	system	df108c26-526b-45dd-a261-59cec44c16fe
7881	Starting execution of job (id=741)	2019-12-02 19:10:00.328286	system	885e1e0b-141c-480b-b797-0c64a248c014
7882	Starting execution of job (id=741)	2019-12-02 19:15:00.674531	system	ebf4d4d6-9a7e-4fd1-830d-df49f0515806
7883	Starting execution of job (id=741)	2019-12-02 19:20:00.021805	system	5c5f5068-2e2a-4de8-96e8-bc3cc854d7a1
7884	Starting execution of job (id=746)	2019-12-02 20:05:00.294041	system	376550a0-b5aa-4583-9088-992da118e9be
7885	Starting execution of job (id=746)	2019-12-02 20:05:01.293808	system	20c87ac8-dbf7-4eee-9ff5-95860eac7d38
7886	Starting execution of job (id=746)	2019-12-02 20:05:02.294754	system	4d3e13dc-d54b-4c1c-8ff1-f3c537c945c3
7887	Starting execution of job (id=746)	2019-12-02 20:05:03.296872	system	c93a0503-5ee3-4882-9836-407930dd1b1a
7888	Starting execution of job (id=746)	2019-12-02 20:05:04.298477	system	80d5edec-45cb-42dc-a14c-c86a46b5f1ff
7889	Starting execution of job (id=746)	2019-12-02 20:05:05.299852	system	686ba36c-a6ce-4dff-9393-1e78ee559607
7890	Starting execution of job (id=746)	2019-12-02 20:05:06.301013	system	b07a7452-b3df-438e-94a9-a07872906b90
7891	Starting execution of job (id=746)	2019-12-02 20:05:07.301322	system	44f64c59-1d25-42ca-9bb6-38464c895474
7892	Starting execution of job (id=746)	2019-12-02 20:05:08.302141	system	c1f14fd7-9610-4baa-a97a-06821f0e741c
7893	Starting execution of job (id=746)	2019-12-02 20:05:09.303944	system	ea087e29-39fc-4d8e-ac12-a06ca29759e2
7894	Starting execution of job (id=746)	2019-12-02 20:05:10.305654	system	83bd4434-df19-49f2-aaf8-a56741058021
7895	Starting execution of job (id=746)	2019-12-02 20:05:11.306715	system	ea9d0dc2-4d84-4469-87fd-8b36caaa3871
7896	Starting execution of job (id=746)	2019-12-02 20:05:12.307764	system	b4a499ea-698f-4d17-94e3-fb53f2ab1a7c
7897	Starting execution of job (id=746)	2019-12-02 20:05:13.309043	system	a2f16009-25ea-4e1b-8921-12ff19e00f3c
7898	Starting execution of job (id=746)	2019-12-02 20:05:14.309234	system	79dfcacb-45e7-4f6d-a56f-e3b032263794
7899	Starting execution of job (id=746)	2019-12-02 20:05:15.311461	system	48a64e4f-35f0-483f-9dad-338a7e6748da
7900	Starting execution of job (id=746)	2019-12-02 20:05:16.313397	system	c87580cc-f58d-4a0f-8d42-9f2751912adf
7901	Starting execution of job (id=746)	2019-12-02 20:05:17.314655	system	8d43a6f9-2d1c-4444-96cb-d4406bcc9d52
7902	Starting execution of job (id=746)	2019-12-02 20:05:18.316102	system	a621cf33-fc11-4a98-b7fa-d949075333dd
7903	Starting execution of job (id=746)	2019-12-02 20:05:19.31548	system	cf75dd2d-1561-42ea-85fa-0c1af17c5ff2
7904	Starting execution of job (id=746)	2019-12-02 20:05:20.318083	system	d63a67b9-ddfc-4cb4-9a91-04e23fca9763
7905	Starting execution of job (id=746)	2019-12-02 20:07:00.840318	system	74bc77db-cd1e-44ea-8b4e-12df454fab3c
7906	Starting execution of job (id=746)	2019-12-02 20:12:00.068104	system	7166b7f9-158b-4728-9f1e-c9697fd4d854
7907	Starting execution of job (id=747)	2019-12-02 20:15:00.777305	system	381a9d83-df50-4abb-956e-fcfbd653391d
7908	Starting execution of job (id=768)	2019-12-04 19:14:00.529916	system	ea7ac28b-c3e8-49f7-94b0-57d48d7f3d84
7909	Starting execution of job (id=768)	2019-12-04 19:22:16.160468	system	38b61c8a-c759-4850-bb05-643fcc958618
7910	Starting execution of job (id=768)	2019-12-04 19:25:00.281628	system	6ea6c013-ea7f-428e-aa5f-ef795e79c3ad
7911	Starting execution of job (id=768)	2019-12-04 19:27:00.416286	system	3c73a6b2-b08c-4a45-8d14-cad3cac5ca56
7912	Starting execution of job (id=768)	2019-12-04 19:33:00.823832	system	c8a3d1a1-295d-4752-b952-a06e0072e6d4
7913	Starting execution of job (id=768)	2019-12-04 19:35:00.940173	system	4a53a84f-f167-45fe-8d32-09eda82ba9c6
7914	Starting execution of job (id=768)	2019-12-04 19:37:57.396465	system	65aa9ae7-2e37-4d4f-b3dc-8a7f55573389
7915	Starting execution of job (id=768)	2019-12-04 19:39:11.343047	system	98a87912-0d90-4f11-a9da-a1bc6f143a1d
7916	Starting execution of job (id=768)	2019-12-04 19:40:26.661835	system	0a3ad324-3263-40c7-ba15-9e3204f83ba4
7917	Starting execution of job (id=768)	2019-12-04 19:49:17.186778	system	964bf9dd-f196-42e3-919f-fcd7d1fd822c
7918	Starting execution of job (id=768)	2019-12-04 19:52:04.643299	system	69998219-7681-4f7b-8ac0-7af99c84be3a
7919	Starting execution of job (id=768)	2019-12-04 19:52:35.56333	system	20a18868-1b8e-4960-a51d-9cf17b60be6f
7920	Starting execution of job (id=768)	2019-12-04 19:54:10.447887	system	916a35f2-10b0-4fe0-9058-cb213da4f75b
7921	Starting execution of job (id=768)	2019-12-04 19:57:12.024314	system	bc88673e-e6fb-4332-bbb0-e7696b62598c
7922	Starting execution of job (id=783)	2019-12-04 20:25:34.990891	system	6c01be37-b5fc-4a6d-8c43-c37c70387646
7923	Starting execution of job (id=784)	2019-12-04 20:25:35.004834	system	6c01be37-b5fc-4a6d-8c43-c37c70387646
7924	Starting execution of job (id=784)	2019-12-04 20:25:35.981789	system	9d7cc98e-4850-419d-885a-7cfc4d2b9115
7925	Starting execution of job (id=784)	2019-12-04 20:25:36.979843	system	9ed788a3-a3b2-411f-a4cd-aaaf7e6dc446
7926	Starting execution of job (id=784)	2019-12-04 20:25:37.98155	system	c38ad994-c784-458e-920e-0053cdd1f6da
7927	Starting execution of job (id=784)	2019-12-04 20:25:38.980763	system	23513906-908a-4a47-903f-41f1144c8b1a
7928	Starting execution of job (id=784)	2019-12-04 20:25:39.985065	system	38e27486-6128-4e30-b670-8d531ff63fae
7929	Starting execution of job (id=784)	2019-12-04 20:25:40.985421	system	60b3ac92-fc23-4de8-bfa7-58b8bd2676aa
7930	Starting execution of job (id=784)	2019-12-04 20:25:41.996562	system	40a2b3dd-932b-4e75-9602-fbad2e1966ec
7931	Starting execution of job (id=784)	2019-12-04 20:25:42.996947	system	50b8a780-a016-4e7b-87ff-6641eab565a2
7932	Starting execution of job (id=784)	2019-12-04 20:25:43.996826	system	e2274b44-5de9-4617-9a06-6ccc4ddc9439
7933	Starting execution of job (id=784)	2019-12-04 20:25:44.999229	system	910a1b6f-5884-4941-b03a-0f80060598d2
7934	Starting execution of job (id=784)	2019-12-04 20:25:46.000718	system	ea5aa0b2-1cc1-4534-baa9-e5091843cec0
7935	Starting execution of job (id=784)	2019-12-04 20:25:47.00212	system	910c62a4-5527-49d2-a54f-37b88f392733
7936	Starting execution of job (id=784)	2019-12-04 20:25:48.003202	system	e9f2447e-5f0d-4cbf-9681-68ecfd3fa845
7937	Starting execution of job (id=784)	2019-12-04 20:25:49.004607	system	0c39c39a-722d-4d8d-86d9-85d029736beb
7938	Starting execution of job (id=784)	2019-12-04 20:25:50.002811	system	801893bd-203f-4a69-b248-b77f4843cb23
\.


--
-- TOC entry 2970 (class 0 OID 0)
-- Dependencies: 197
-- Name: refJobStatus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."refJobStatus_id_seq"', 4, true);


--
-- TOC entry 2971 (class 0 OID 0)
-- Dependencies: 199
-- Name: tblConnection_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblConnection_id_seq"', 671, true);


--
-- TOC entry 2972 (class 0 OID 0)
-- Dependencies: 202
-- Name: tblJobHistory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblJobHistory_id_seq"', 15778, true);


--
-- TOC entry 2973 (class 0 OID 0)
-- Dependencies: 203
-- Name: tblJob_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblJob_Id_seq"', 1130, true);


--
-- TOC entry 2974 (class 0 OID 0)
-- Dependencies: 205
-- Name: tblLog_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblLog_Id_seq"', 4732, true);


--
-- TOC entry 2975 (class 0 OID 0)
-- Dependencies: 207
-- Name: tblRunHistory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblRunHistory_id_seq"', 7938, true);


--
-- TOC entry 2813 (class 2606 OID 16469)
-- Name: refJobStatus refJobStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."refJobStatus"
    ADD CONSTRAINT "refJobStatus_pkey" PRIMARY KEY (id);


--
-- TOC entry 2815 (class 2606 OID 16471)
-- Name: tblConnection tblConnection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblConnection"
    ADD CONSTRAINT "tblConnection_pkey" PRIMARY KEY (id);


--
-- TOC entry 2823 (class 2606 OID 16473)
-- Name: tblRunHistory tblHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblRunHistory"
    ADD CONSTRAINT "tblHistory_pkey" PRIMARY KEY (id);


--
-- TOC entry 2819 (class 2606 OID 16475)
-- Name: tblJobHistory tblJobHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory"
    ADD CONSTRAINT "tblJobHistory_pkey" PRIMARY KEY (id);


--
-- TOC entry 2817 (class 2606 OID 16477)
-- Name: tblJob tblJob_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob"
    ADD CONSTRAINT "tblJob_pkey" PRIMARY KEY (id);


--
-- TOC entry 2821 (class 2606 OID 16479)
-- Name: tblLog tblLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblLog"
    ADD CONSTRAINT "tblLog_pkey" PRIMARY KEY (id);


--
-- TOC entry 2824 (class 2606 OID 16480)
-- Name: tblJob tbljob_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob"
    ADD CONSTRAINT tbljob_fk FOREIGN KEY ("statusId") REFERENCES public."refJobStatus"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2825 (class 2606 OID 16485)
-- Name: tblJobHistory tbljobhistory_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory"
    ADD CONSTRAINT tbljobhistory_fk FOREIGN KEY ("jobId") REFERENCES public."tblJob"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


-- Completed on 2019-12-08 14:10:54 MSK

--
-- PostgreSQL database dump complete
--

