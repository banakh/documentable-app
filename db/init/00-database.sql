create extension if not exists pgcrypto;

drop user if exists app_user;
create user app_user password '1x9T4d7G2k';

create table public.group (
    id uuid not null default gen_random_uuid(),
    name varchar not null,
    constraint pk_group primary key (id)
);

create table public."user" (
    id uuid not null default gen_random_uuid(),
    username varchar not null,
    password varchar not null,
    constraint pk_owner primary key (id)
);
create unique index uniq_idx_user_username on public."user"(username);

create table public.membership (
    id uuid not null default gen_random_uuid(),
    group_id uuid not null,
    user_id uuid not null,
    constraint pk_membership primary key (id),
    constraint fk_membership_group_id foreign key (group_id) references public.group(id),
    constraint fk_membership_user_id foreign key (user_id) references public."user"(id)
);
create unique index uniq_idx_membership_group_id_user_id on public.membership(group_id, user_id);

create table public.folder (
    id uuid not null default gen_random_uuid(),
    group_id uuid not null,
    name varchar not null,
    created_at timestamp not null default now(),
    constraint pk_folder primary key (id),
    constraint fk_folder_group_id foreign key (group_id) references public.group(id)
);
create unique index uniq_idx_folder_group_id_name on folder(group_id, name);

create table public.document (
    id uuid not null default gen_random_uuid(),
    folder_id uuid not null,
    owner_id uuid not null,
    name varchar not null,
    body varchar,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now(),
    constraint pk_document primary key (id),
    constraint fk_document_folder_id foreign key (folder_id) references public.folder(id),
    constraint fk_document_owner_id foreign key (owner_id) references public."user"(id)
);
create unique index uniq_idx_document_folder_id_name on document(folder_id, name);


create table public.execution (
    id uuid not null default gen_random_uuid(),
    document_id uuid not null,
    result jsonb not null,
    executed_at timestamp not null default now(),
    constraint pk_execution primary key (id),
    constraint fk_execution_document_id foreign key (document_id) references public.document(id)
);

create type public.jwt_token as (
    role text,
    exp integer,
    username varchar,
    user_id uuid
);

create or replace function public.sign_up(_username text, _password text)
returns void
volatile
language plpgsql
as $$
begin
    insert into public."user" (username, password)
    select sign_up._username, crypt(sign_up._password, gen_salt('bf', 8));
end
$$;

create or replace function public.add_group(_group_name varchar, _user_id uuid)
returns table (user_id uuid, group_id uuid, group_name varchar)
volatile
language plpgsql
as $$
begin
    if (select exists(select m.id
        from public.membership m
                 join public."group" g on m.group_id = g.id
        where m.user_id = add_group._user_id
          and g.name = add_group._group_name))
    then
        raise exception 'user already has group with this name';
    else
        return query (
            with insert_group as (
                insert into public.group (name) values (add_group._group_name)
                    returning id
            ),
            insert_membership as (
                insert into public.membership (group_id, user_id)
                    select id, add_group._user_id from insert_group
                    returning membership.group_id, membership.user_id
            )
            select im.group_id,
                   im.user_id,
                   add_group._group_name
            from insert_membership im
        );
    end if;
    end
$$;

create or replace function public.authenticate(_username text, _password text)
returns public.jwt_token as $$
declare
  "user" public."user";
begin
  select u.* into "user"
    from public."user" as u
    where u.username = authenticate._username;

  if "user".password = crypt(_password, "user".password) then
    return (
      'app_user',
      extract(epoch from now() + interval '7 days'),
      "user".username,
      "user".id
    )::public.jwt_token;
  else
    return null;
  end if;
end;
$$ language plpgsql;

create or replace function public.current_user_name()
returns varchar
as $$
  select nullif(current_setting('jwt.claims.username', true), '')::varchar;
$$ language sql stable;

create or replace function public.current_user_id()
returns uuid
as $$
  select nullif(current_setting('jwt.claims.user_id', true), '')::uuid;
$$ language sql stable;

-- cls
grant select, insert, delete, update on public."user" to app_user;
grant select, insert, delete, update on public."group" to app_user;
grant select, insert, delete, update on public."membership" to app_user;

-- rls
---- user
create policy user_policy_select on public."user" for select using (true);
create policy user_policy_update on public."user" for update using (username = public.current_user_name());
create policy user_policy_delete on public."user" for delete using (username = public.current_user_name());
create policy user_policy_insert on public."user" for insert with check (true);
alter table public."user" enable row level security;

---- membership
create policy membership_policy_select on public."membership" for select using (user_id = public.current_user_id());
create policy membership_policy_update on public."membership" for update using (user_id = public.current_user_id());
create policy membership_policy_delete on public."membership" for delete using (user_id = public.current_user_id());
create policy membership_policy_insert on public."membership" for insert with check (true);
alter table public."membership" enable row level security;
