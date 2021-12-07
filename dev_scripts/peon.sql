--
-- PostgreSQL database dump
--

-- Dumped from database version 13.3 (Debian 13.3-1.pgdg100+1)
-- Dumped by pg_dump version 14.1 (Ubuntu 14.1-2.pgdg20.04+1)

-- Started on 2021-12-07 00:36:49 MSK

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
-- TOC entry 216 (class 1255 OID 16385)
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
-- TOC entry 250 (class 1255 OID 16386)
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
			j.body::json->>'name' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
			or j.body::json->>'host' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
			or j.body::json->>'port' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
			or j.body::json->>'login' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
			or j.body::json->>'type' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
		) 
$$;


--
-- TOC entry 218 (class 1255 OID 16387)
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
-- TOC entry 247 (class 1255 OID 33362)
-- Name: fnConnection_Insert(json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Insert"(body json, created_by text) RETURNS integer
    LANGUAGE sql
    AS $$
    INSERT INTO public."tblConnection"("body", "modifiedBy", "createdBy") VALUES (body, created_by, created_by) RETURNING "id"
$$;


--
-- TOC entry 219 (class 1255 OID 16389)
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
-- TOC entry 248 (class 1255 OID 16390)
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
		when 'name' then 'j.body::json->>''name'''
		when 'host' then 'j.body::json->>''host'''
		when 'port' then 'j.body::json->>''port'''
		when 'enabled' then 'j.body::json->>''enabled'''
		when 'login' then 'j.body::json->>''login'''
		when 'type' then 'j.body::json->>''type'''
		else 'j.id'
	end;
	
	RETURN QUERY EXECUTE '         
    select
		json_agg(t.*)
	from
		(
		select
			j.id,
			j.body::json->>''name'' as name,
			j.body::json->>''host'' as host,
			CAST(j.body::json->>''enabled'' as bool) as enabled,
			CAST(j.body::json->>''port'' as integer) as port,
			j.body::json->>''login'' as login,
			j.body::json->>''password'' as password,
			j.body::json->>''type'' as type,
			j."createdOn" as created_on,
			j."createdBy" as created_by,
			j."modifiedOn" as modified_on,
			j."modifiedBy" as modified_by
		from
			"tblConnection" j
		where
			nullif(j."isDeleted", false) is null
			and (
				j.body::json->>''name'' like ''%' || regexp_replace($1, '[^\w\s\,\-_]+','') || '%''
				or j.body::json->>''host'' like ''%' || regexp_replace($1, '[^\w\.\-_]+','') || '%''
				or j.body::json->>''port'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
				or j.body::json->>''login'' like ''%' || regexp_replace($1, '[^\w]+','') || '%''
				or j.body::json->>''type'' like ''%' || regexp_replace($1, '[^\w\.\-_]+','') || '%''
			)
		order by ' || sort_expression || ' ' || regexp_replace($3, '[^\w]+','') ||
		' limit ' || $4 || ' offset ' || ($5-1)*$4 || ') t;'
	USING _filtertext, _sortcolumn, _sortorder, _perpage, _page;	
end;

$_$;


--
-- TOC entry 249 (class 1255 OID 16391)
-- Name: fnConnection_Update(integer, json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnConnection_Update"(connection_id integer, connection_body json, modified_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblConnection" j SET 
		"body" = connection_body,
		"modifiedBy" = modified_by,
		"modifiedOn" = NOW()
	WHERE "id" = connection_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 256 (class 1255 OID 16392)
-- Name: fnGetJobStatusId(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnGetJobStatusId"(status text) RETURNS integer
    LANGUAGE sql
    AS $_$
SELECT Id FROM public."refJobStatus" r where r.status = $1
$_$;


--
-- TOC entry 220 (class 1255 OID 16393)
-- Name: fnJobHistory_Insert(json, uuid, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJobHistory_Insert"(message json, session_id uuid, job_id integer, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblJobHistory"("message", "session", "jobId", "createdBy") VALUES (message, session_id, job_id, createdBy) RETURNING "id" $$;


--
-- TOC entry 251 (class 1255 OID 16394)
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
			j.body::json->>'name' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
			or j.body::json->>'description' like '%' || regexp_replace(_filtertext, '[^\w]+','') || '%'
		) 
$$;


--
-- TOC entry 221 (class 1255 OID 16395)
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
-- TOC entry 252 (class 1255 OID 33363)
-- Name: fnJob_Insert(json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Insert"(body json, created_by text) RETURNS integer
    LANGUAGE sql
    AS $$
    INSERT INTO public."tblJob"("body", "modifiedBy", "createdBy") VALUES (body, created_by, created_by) RETURNING "id"
$$;


--
-- TOC entry 222 (class 1255 OID 16397)
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
-- TOC entry 223 (class 1255 OID 16398)
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
-- TOC entry 253 (class 1255 OID 16399)
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
		when 'name' then 'j.body::json->>''name'''
		when 'description' then 'j.body::json->>''description'''
		when 'enabled' then 'j.body::json->>''enabled'''
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
			j.body::json->>''name'' as name,
			j.body::json->>''description'' as description,
			CAST(j.body::json->>''enabled'' as bool) as enabled,
			js.status as status,
			json_array_length(j.body::json#>''{steps}'') as step_count,
			json_array_length(j.body::json#>''{schedules}'') as schedule_count,
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
				j.body::json->>''name'' like ''%' || regexp_replace($1, '[^\w\s\,\-_]+','') || '%''
				or j.body::json->>''description'' like ''%' || regexp_replace($1, '[^\w\s\,\-_]+','') || '%''
			)
		order by ' || sort_expression || ' ' || regexp_replace($3, '[^\w]+','') ||
		' limit ' || $4 || ' offset ' || ($5-1)*$4 || ') t;'
	USING _filtertext, _sortcolumn, _sortorder, _perpage, _page;	
end;

$_$;


--
-- TOC entry 254 (class 1255 OID 16400)
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
			j.body,
			j."nextRun" 
		from
			"tblJob" j
			inner join "refJobStatus" js on j."statusId" = js.id
		where
			nullif(j."isDeleted", false) is null
			and CAST(j.body::json->>'enabled' as bool) = true
			and (j."nextRun" < now() or j."nextRun" is null)
		order by j.id) t;
$$;


--
-- TOC entry 224 (class 1255 OID 16401)
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
-- TOC entry 243 (class 1255 OID 16402)
-- Name: fnJob_Update(integer, json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Update"(job_id integer, job_body json, modified_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"body" = job_body,
		"modifiedBy" = modified_by,
		"modifiedOn" = NOW()
	WHERE "id" = job_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 255 (class 1255 OID 16403)
-- Name: fnJob_Update(integer, json, timestamp without time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnJob_Update"(job_id integer, job_body json, next_run timestamp without time zone, modified_by text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 
	affected integer;
BEGIN
    UPDATE public."tblJob" j SET 
		"body" = job_body,
		"nextRun" = next_run,
		"modifiedBy" = modified_by,
		"modifiedOn" = NOW()
	WHERE "id" = job_id AND NULLIF("isDeleted", false) IS NULL;
	GET DIAGNOSTICS affected := ROW_COUNT;
	RETURN affected as affected;
END ;
$$;


--
-- TOC entry 236 (class 1255 OID 16404)
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
-- TOC entry 237 (class 1255 OID 16405)
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
-- TOC entry 238 (class 1255 OID 16406)
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
-- TOC entry 239 (class 1255 OID 16407)
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
-- TOC entry 240 (class 1255 OID 16408)
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
-- TOC entry 241 (class 1255 OID 16409)
-- Name: fnLog_Insert(integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnLog_Insert"(type integer, message text, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblLog"("type", "message", "createdBy") VALUES (type, message, createdBy) RETURNING "id" $$;


--
-- TOC entry 242 (class 1255 OID 16410)
-- Name: fnRunHistory_Insert(text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnRunHistory_Insert"(message text, session_id uuid, createdby text) RETURNS integer
    LANGUAGE sql
    AS $$INSERT INTO public."tblRunHistory"("message", "session", "createdBy") VALUES (message, session_id, createdBy) RETURNING "id" $$;


--
-- TOC entry 217 (class 1255 OID 33350)
-- Name: fnUser_Insert(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnUser_Insert"(email text, created_by text) RETURNS integer
    LANGUAGE sql
    AS $$
    INSERT INTO public."tblUser"("email", "modifiedBy", "createdBy") VALUES (email, created_by, created_by) RETURNING "id"
$$;


--
-- TOC entry 244 (class 1255 OID 33360)
-- Name: fnUser_Insert(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnUser_Insert"(email text, hash text, salt text, created_by text) RETURNS integer
    LANGUAGE sql
    AS $$
    INSERT INTO public."tblUser"("email", "hash", "salt", "modifiedBy", "createdBy") VALUES (email, hash, salt, created_by, created_by) RETURNING "id"
$$;


--
-- TOC entry 246 (class 1255 OID 33351)
-- Name: fnUser_SelectByEmail(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnUser_SelectByEmail"(email text) RETURNS json
    LANGUAGE sql
    AS $_$
	SELECT row_to_json("tblUser") 
	FROM "tblUser" 
	WHERE "email" = $1 AND NULLIF("isDeleted", false) IS NULL;
$_$;


--
-- TOC entry 245 (class 1255 OID 33352)
-- Name: fnUser_SelectById(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public."fnUser_SelectById"(id integer) RETURNS json
    LANGUAGE sql
    AS $_$
	SELECT row_to_json("tblUser") 
	FROM "tblUser" 
	WHERE "id" = $1 AND NULLIF("isDeleted", false) IS NULL;
$_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 200 (class 1259 OID 16411)
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
-- TOC entry 201 (class 1259 OID 16418)
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
-- TOC entry 202 (class 1259 OID 16420)
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
-- TOC entry 203 (class 1259 OID 16428)
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
-- TOC entry 3055 (class 0 OID 0)
-- Dependencies: 203
-- Name: refJobStatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."refJobStatus_id_seq" OWNED BY public."refJobStatus".id;


--
-- TOC entry 204 (class 1259 OID 16430)
-- Name: tblConnection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."tblConnection" (
    id integer NOT NULL,
    body json,
    "modifiedOn" timestamp without time zone DEFAULT now() NOT NULL,
    "modifiedBy" text NOT NULL,
    "createdOn" timestamp without time zone DEFAULT now() NOT NULL,
    "createdBy" text NOT NULL,
    "isDeleted" boolean
);


--
-- TOC entry 205 (class 1259 OID 16438)
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
-- TOC entry 3056 (class 0 OID 0)
-- Dependencies: 205
-- Name: tblConnection_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblConnection_id_seq" OWNED BY public."tblConnection".id;


--
-- TOC entry 206 (class 1259 OID 16440)
-- Name: tblJob; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."tblJob" (
    id integer NOT NULL,
    body json,
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
-- TOC entry 207 (class 1259 OID 16449)
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
-- TOC entry 208 (class 1259 OID 16456)
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
-- TOC entry 3057 (class 0 OID 0)
-- Dependencies: 208
-- Name: tblJobHistory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblJobHistory_id_seq" OWNED BY public."tblJobHistory".id;


--
-- TOC entry 209 (class 1259 OID 16458)
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
-- TOC entry 3058 (class 0 OID 0)
-- Dependencies: 209
-- Name: tblJob_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblJob_Id_seq" OWNED BY public."tblJob".id;


--
-- TOC entry 210 (class 1259 OID 16460)
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
-- TOC entry 211 (class 1259 OID 16467)
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
-- TOC entry 3059 (class 0 OID 0)
-- Dependencies: 211
-- Name: tblLog_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblLog_Id_seq" OWNED BY public."tblLog".id;


--
-- TOC entry 212 (class 1259 OID 16469)
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
-- TOC entry 213 (class 1259 OID 16476)
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
-- TOC entry 3060 (class 0 OID 0)
-- Dependencies: 213
-- Name: tblRunHistory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblRunHistory_id_seq" OWNED BY public."tblRunHistory".id;


--
-- TOC entry 215 (class 1259 OID 33338)
-- Name: tblUser; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."tblUser" (
    id integer NOT NULL,
    email text NOT NULL,
    salt text NOT NULL,
    "modifiedBy" text NOT NULL,
    "createdOn" timestamp without time zone DEFAULT now() NOT NULL,
    "createdBy" text NOT NULL,
    "isDeleted" boolean,
    hash text NOT NULL
);


--
-- TOC entry 214 (class 1259 OID 33336)
-- Name: tblUsers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."tblUsers_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3061 (class 0 OID 0)
-- Dependencies: 214
-- Name: tblUsers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."tblUsers_id_seq" OWNED BY public."tblUser".id;


--
-- TOC entry 2886 (class 2604 OID 16478)
-- Name: refJobStatus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."refJobStatus" ALTER COLUMN id SET DEFAULT nextval('public."refJobStatus_id_seq"'::regclass);


--
-- TOC entry 2889 (class 2604 OID 16479)
-- Name: tblConnection id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblConnection" ALTER COLUMN id SET DEFAULT nextval('public."tblConnection_id_seq"'::regclass);


--
-- TOC entry 2893 (class 2604 OID 16480)
-- Name: tblJob id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob" ALTER COLUMN id SET DEFAULT nextval('public."tblJob_Id_seq"'::regclass);


--
-- TOC entry 2895 (class 2604 OID 16481)
-- Name: tblJobHistory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory" ALTER COLUMN id SET DEFAULT nextval('public."tblJobHistory_id_seq"'::regclass);


--
-- TOC entry 2897 (class 2604 OID 16482)
-- Name: tblLog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblLog" ALTER COLUMN id SET DEFAULT nextval('public."tblLog_Id_seq"'::regclass);


--
-- TOC entry 2899 (class 2604 OID 16483)
-- Name: tblRunHistory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblRunHistory" ALTER COLUMN id SET DEFAULT nextval('public."tblRunHistory_id_seq"'::regclass);


--
-- TOC entry 2900 (class 2604 OID 33341)
-- Name: tblUser id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblUser" ALTER COLUMN id SET DEFAULT nextval('public."tblUsers_id_seq"'::regclass);


--
-- TOC entry 2903 (class 2606 OID 16485)
-- Name: sysAbyss abyss_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."sysAbyss"
    ADD CONSTRAINT abyss_pk PRIMARY KEY (id);


--
-- TOC entry 2905 (class 2606 OID 16487)
-- Name: refJobStatus refJobStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."refJobStatus"
    ADD CONSTRAINT "refJobStatus_pkey" PRIMARY KEY (id);


--
-- TOC entry 2907 (class 2606 OID 16489)
-- Name: tblConnection tblConnection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblConnection"
    ADD CONSTRAINT "tblConnection_pkey" PRIMARY KEY (id);


--
-- TOC entry 2915 (class 2606 OID 16491)
-- Name: tblRunHistory tblHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblRunHistory"
    ADD CONSTRAINT "tblHistory_pkey" PRIMARY KEY (id);


--
-- TOC entry 2911 (class 2606 OID 16493)
-- Name: tblJobHistory tblJobHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory"
    ADD CONSTRAINT "tblJobHistory_pkey" PRIMARY KEY (id);


--
-- TOC entry 2909 (class 2606 OID 16495)
-- Name: tblJob tblJob_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob"
    ADD CONSTRAINT "tblJob_pkey" PRIMARY KEY (id);


--
-- TOC entry 2913 (class 2606 OID 16497)
-- Name: tblLog tblLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblLog"
    ADD CONSTRAINT "tblLog_pkey" PRIMARY KEY (id);


--
-- TOC entry 2917 (class 2606 OID 33347)
-- Name: tblUser tblUsers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblUser"
    ADD CONSTRAINT "tblUsers_pkey" PRIMARY KEY (id);


--
-- TOC entry 2918 (class 2606 OID 16498)
-- Name: tblJob tbljob_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJob"
    ADD CONSTRAINT tbljob_fk FOREIGN KEY ("statusId") REFERENCES public."refJobStatus"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2919 (class 2606 OID 16503)
-- Name: tblJobHistory tbljobhistory_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."tblJobHistory"
    ADD CONSTRAINT tbljobhistory_fk FOREIGN KEY ("jobId") REFERENCES public."tblJob"(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


-- Completed on 2021-12-07 00:36:56 MSK

--
-- PostgreSQL database dump complete
--

