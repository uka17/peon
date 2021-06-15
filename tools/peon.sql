--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2 (Debian 13.2-1.pgdg100+1)
-- Dumped by pg_dump version 13.3 (Ubuntu 13.3-1.pgdg20.04+1)

-- Started on 2021-06-16 00:41:04 MSK

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
-- TOC entry 248 (class 1255 OID 16577)
-- Name: _fnWipe(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."_fnWipe"() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
	truncate table "sysAbyss";
	truncate table "tblJobHistory";
	truncate table "tblLog";
	truncate table "tblRunHistory";
	truncate table "tblConnection";
	truncate table "tblJob" CASCADE;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 214 (class 1255 OID 16385)
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
-- TOC entry 215 (class 1255 OID 16386)
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
-- TOC entry 216 (class 1255 OID 16387)
-- Name: fnConnection_Insert(json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Insert"(connection json, created_by text) RETURNS integer
    LANGUAGE sql
    AS $$
    INSERT INTO public."tblConnection"("connection", "modifiedBy", "createdBy") VALUES (connection, created_by, created_by) RETURNING "id"
$$;


--
-- TOC entry 217 (class 1255 OID 16388)
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
-- TOC entry 244 (class 1255 OID 16389)
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
				j.connection::json->>''name'' like ''%' || regexp_replace($1, '[^\w\s\,\-_]+','') || '%''
				or j.connection::json->>''host'' like ''%' || regexp_replace($1, '[^\w\.\-_]+','') || '%''
				or j.connection::json->>''port'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
				or j.connection::json->>''login'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
				or j.connection::json->>''type'' like ''%' || regexp_replace($1, '[^\w\.\-_]+','') || '%''
			)
		order by ' || sort_expression || ' ' || regexp_replace($3, '[^\w]+','') ||
		' limit ' || $4 || ' offset ' || ($5-1)*$4 || ') t;'
	USING _filtertext, _sortcolumn, _sortorder, _perpage, _page;	
end;

$_$;


--
-- TOC entry 218 (class 1255 OID 16390)
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
-- TOC entry 219 (class 1255 OID 16391)
-- Name: fnGetJobStatusId(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnGetJobStatusId"(status text) RETURNS integer
    LANGUAGE sql
    AS $$SELECT Id FROM public."refJobStatus" r where r.status = status$$;


--
-- TOC entry 220 (class 1255 OID 16392)
-- Name: fnJobHistory_Insert(json, uuid, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJobHistory_Insert"(message json, session_id uuid, job_id integer, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblJobHistory"("message", "session", "jobId", "createdBy") VALUES (message, session_id, job_id, createdBy) RETURNING "id" $$;


--
-- TOC entry 221 (class 1255 OID 16393)
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
-- TOC entry 222 (class 1255 OID 16394)
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
-- TOC entry 223 (class 1255 OID 16395)
-- Name: fnJob_Insert(json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Insert"(job json, created_by text) RETURNS integer
    LANGUAGE sql
    AS $$
    INSERT INTO public."tblJob"("job", "modifiedBy", "createdBy") VALUES (job, created_by, created_by) RETURNING "id"
$$;


--
-- TOC entry 243 (class 1255 OID 16865)
-- Name: fnJob_ResetAll(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_ResetAll"() RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"statusId" = 1;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 224 (class 1255 OID 16396)
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
-- TOC entry 245 (class 1255 OID 16397)
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
				j.job::json->>''name'' like ''%' || regexp_replace($1, '[^\w\s\,\-_]+','') || '%''
				or j.job::json->>''description'' like ''%' || regexp_replace($1, '[^\w\s\,\-_]+','') || '%''
			)
		order by ' || sort_expression || ' ' || regexp_replace($3, '[^\w]+','') ||
		' limit ' || $4 || ' offset ' || ($5-1)*$4 || ') t;'
	USING _filtertext, _sortcolumn, _sortorder, _perpage, _page;	
end;

$_$;


--
-- TOC entry 247 (class 1255 OID 16860)
-- Name: fnJob_SelectAllOverdue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_SelectAllOverdue"() RETURNS SETOF json
    LANGUAGE sql
    AS $$      
    select
		json_agg(t.*)
	from
		(
		select
			j.id,
			j.job,
			j."nextRun" 
		from
			"tblJob" j
			inner join "refJobStatus" js on j."statusId" = js.id
		where
			nullif(j."isDeleted", false) is null
			and CAST(j.job::json->>'enabled' as bool) = true
			and (j."nextRun" < now() or j."nextRun" is null)
		order by j.id) t;
$$;


--
-- TOC entry 242 (class 1255 OID 16398)
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
	      and nullif(j."isDeleted", false) is null
		 ) t;
$$;


--
-- TOC entry 225 (class 1255 OID 16399)
-- Name: fnJob_Update(integer, json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Update"(job_id integer, job_body json, modified_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"job" = job_body,
		"modifiedBy" = modified_by,
		"modifiedOn" = NOW()
	WHERE "id" = job_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 237 (class 1255 OID 16400)
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
-- TOC entry 249 (class 1255 OID 17242)
-- Name: fnJob_UpdateLastRun(integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_UpdateLastRun"(_job_id integer, _success boolean) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"lastRunOn" = NOW(),
		"lastRunResult" = _success
	WHERE "id" = _job_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 238 (class 1255 OID 16401)
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
-- TOC entry 246 (class 1255 OID 16861)
-- Name: fnJob_UpdateNextRun(integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_UpdateNextRun"(job_id integer, next_run timestamp without time zone) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"nextRun" = next_run
	WHERE "id" = job_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 250 (class 1255 OID 17243)
-- Name: fnJob_UpdateStatus(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_UpdateStatus"(job_id integer, status_id integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"statusId" = status_id
	WHERE "id" = job_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 239 (class 1255 OID 16403)
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
-- TOC entry 240 (class 1255 OID 16404)
-- Name: fnLog_Insert(integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnLog_Insert"(type integer, message text, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblLog"("type", "message", "createdBy") VALUES (type, message, createdBy) RETURNING "id" $$;


--
-- TOC entry 241 (class 1255 OID 16405)
-- Name: fnRunHistory_Insert(text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnRunHistory_Insert"(message text, session_id uuid, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblRunHistory"("message", "session", "createdBy") VALUES (message, session_id, createdBy) RETURNING "id" $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 213 (class 1259 OID 17189)
-- Name: sysAbyss; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."sysAbyss" (
    id integer NOT NULL,
    text character varying,
    number integer,
    json json,
    modified timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- TOC entry 212 (class 1259 OID 17187)
-- Name: abyss_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public."sysAbyss" ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.abyss_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 200 (class 1259 OID 16406)
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
-- TOC entry 201 (class 1259 OID 16414)
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
-- TOC entry 3054 (class 0 OID 0)
-- Dependencies: 201
-- Name: refJobStatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."refJobStatus_id_seq" OWNED BY public."refJobStatus".id;


--
-- TOC entry 202 (class 1259 OID 16416)
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
-- TOC entry 203 (class 1259 OID 16424)
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
-- TOC entry 3055 (class 0 OID 0)
-- Dependencies: 203
-- Name: tblConnection_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblConnection_id_seq" OWNED BY public."tblConnection".id;


--
-- TOC entry 204 (class 1259 OID 16426)
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
-- TOC entry 205 (class 1259 OID 16435)
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
-- TOC entry 206 (class 1259 OID 16442)
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
-- TOC entry 3056 (class 0 OID 0)
-- Dependencies: 206
-- Name: tblJobHistory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblJobHistory_id_seq" OWNED BY public."tblJobHistory".id;


--
-- TOC entry 207 (class 1259 OID 16444)
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
-- TOC entry 3057 (class 0 OID 0)
-- Dependencies: 207
-- Name: tblJob_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblJob_Id_seq" OWNED BY public."tblJob".id;


--
-- TOC entry 208 (class 1259 OID 16446)
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
-- TOC entry 209 (class 1259 OID 16453)
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
-- TOC entry 3058 (class 0 OID 0)
-- Dependencies: 209
-- Name: tblLog_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblLog_Id_seq" OWNED BY public."tblLog".id;


--
-- TOC entry 210 (class 1259 OID 16455)
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
-- TOC entry 211 (class 1259 OID 16462)
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
-- TOC entry 3059 (class 0 OID 0)
-- Dependencies: 211
-- Name: tblRunHistory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblRunHistory_id_seq" OWNED BY public."tblRunHistory".id;


--
-- TOC entry 2874 (class 2604 OID 16464)
-- Name: refJobStatus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."refJobStatus" ALTER COLUMN id SET DEFAULT nextval('public."refJobStatus_id_seq"'::regclass);


--
-- TOC entry 2877 (class 2604 OID 16465)
-- Name: tblConnection id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblConnection" ALTER COLUMN id SET DEFAULT nextval('public."tblConnection_id_seq"'::regclass);


--
-- TOC entry 2881 (class 2604 OID 16466)
-- Name: tblJob id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob" ALTER COLUMN id SET DEFAULT nextval('public."tblJob_Id_seq"'::regclass);


--
-- TOC entry 2883 (class 2604 OID 16467)
-- Name: tblJobHistory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory" ALTER COLUMN id SET DEFAULT nextval('public."tblJobHistory_id_seq"'::regclass);


--
-- TOC entry 2885 (class 2604 OID 16468)
-- Name: tblLog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblLog" ALTER COLUMN id SET DEFAULT nextval('public."tblLog_Id_seq"'::regclass);


--
-- TOC entry 2887 (class 2604 OID 16469)
-- Name: tblRunHistory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblRunHistory" ALTER COLUMN id SET DEFAULT nextval('public."tblRunHistory_id_seq"'::regclass);


--
-- TOC entry 3035 (class 0 OID 16406)
-- Dependencies: 200
-- Data for Name: refJobStatus; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."refJobStatus" (id, status, "modifiedOn", "modifiedBy", "createdOn", "createdBy", "isDeleted") FROM stdin;
1	Idle	2019-05-18 00:36:30.585459	system	2019-05-18 00:36:30.585459	system	\N
2	Execution	2019-05-18 00:36:30.585459	system	2019-05-18 00:36:30.585459	system	\N
\.


--
-- TOC entry 3048 (class 0 OID 17189)
-- Dependencies: 213
-- Data for Name: sysAbyss; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."sysAbyss" (id, text, number, json, modified) FROM stdin;
\.


--
-- TOC entry 3037 (class 0 OID 16416)
-- Dependencies: 202
-- Data for Name: tblConnection; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblConnection" (id, connection, "modifiedOn", "modifiedBy", "createdOn", "createdBy", "isDeleted") FROM stdin;
\.


--
-- TOC entry 3039 (class 0 OID 16426)
-- Dependencies: 204
-- Data for Name: tblJob; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblJob" (id, job, "modifiedOn", "modifiedBy", "createdOn", "createdBy", "isDeleted", "statusId", "nextRun", "lastRunOn", "lastRunResult") FROM stdin;
\.


--
-- TOC entry 3040 (class 0 OID 16435)
-- Dependencies: 205
-- Data for Name: tblJobHistory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblJobHistory" (id, message, "createdOn", "createdBy", "jobId", session) FROM stdin;
\.


--
-- TOC entry 3043 (class 0 OID 16446)
-- Dependencies: 208
-- Data for Name: tblLog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblLog" (id, type, message, "createdOn", "createdBy") FROM stdin;
\.


--
-- TOC entry 3045 (class 0 OID 16455)
-- Dependencies: 210
-- Data for Name: tblRunHistory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."tblRunHistory" (id, message, "createdOn", "createdBy", session) FROM stdin;
\.


--
-- TOC entry 3060 (class 0 OID 0)
-- Dependencies: 212
-- Name: abyss_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.abyss_id_seq', 4360, true);


--
-- TOC entry 3061 (class 0 OID 0)
-- Dependencies: 201
-- Name: refJobStatus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."refJobStatus_id_seq"', 4, true);


--
-- TOC entry 3062 (class 0 OID 0)
-- Dependencies: 203
-- Name: tblConnection_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblConnection_id_seq"', 1055, true);


--
-- TOC entry 3063 (class 0 OID 0)
-- Dependencies: 206
-- Name: tblJobHistory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblJobHistory_id_seq"', 70038, true);


--
-- TOC entry 3064 (class 0 OID 0)
-- Dependencies: 207
-- Name: tblJob_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblJob_Id_seq"', 2506, true);


--
-- TOC entry 3065 (class 0 OID 0)
-- Dependencies: 209
-- Name: tblLog_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblLog_Id_seq"', 4841, true);


--
-- TOC entry 3066 (class 0 OID 0)
-- Dependencies: 211
-- Name: tblRunHistory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."tblRunHistory_id_seq"', 18047, true);


--
-- TOC entry 2902 (class 2606 OID 17197)
-- Name: sysAbyss abyss_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."sysAbyss"
    ADD CONSTRAINT abyss_pk PRIMARY KEY (id);


--
-- TOC entry 2890 (class 2606 OID 16471)
-- Name: refJobStatus refJobStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."refJobStatus"
    ADD CONSTRAINT "refJobStatus_pkey" PRIMARY KEY (id);


--
-- TOC entry 2892 (class 2606 OID 16473)
-- Name: tblConnection tblConnection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblConnection"
    ADD CONSTRAINT "tblConnection_pkey" PRIMARY KEY (id);


--
-- TOC entry 2900 (class 2606 OID 16475)
-- Name: tblRunHistory tblHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblRunHistory"
    ADD CONSTRAINT "tblHistory_pkey" PRIMARY KEY (id);


--
-- TOC entry 2896 (class 2606 OID 16477)
-- Name: tblJobHistory tblJobHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory"
    ADD CONSTRAINT "tblJobHistory_pkey" PRIMARY KEY (id);


--
-- TOC entry 2894 (class 2606 OID 16479)
-- Name: tblJob tblJob_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob"
    ADD CONSTRAINT "tblJob_pkey" PRIMARY KEY (id);


--
-- TOC entry 2898 (class 2606 OID 16481)
-- Name: tblLog tblLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblLog"
    ADD CONSTRAINT "tblLog_pkey" PRIMARY KEY (id);


--
-- TOC entry 2903 (class 2606 OID 16482)
-- Name: tblJob tbljob_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob"
    ADD CONSTRAINT tbljob_fk FOREIGN KEY ("statusId") REFERENCES public."refJobStatus"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2904 (class 2606 OID 16487)
-- Name: tblJobHistory tbljobhistory_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory"
    ADD CONSTRAINT tbljobhistory_fk FOREIGN KEY ("jobId") REFERENCES public."tblJob"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


-- Completed on 2021-06-16 00:41:07 MSK

--
-- PostgreSQL database dump complete
--

