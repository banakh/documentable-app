create extension if not exists pgcrypto;

create role app_postgraphile login password '1y2t3BNSq498qL';

create role app_anonymous;
grant app_anonymous to app_postgraphile;

create role app_user;
grant app_user to app_postgraphile;

create schema app_public;
create schema app_private;

create table app_public."user" (
    id uuid default gen_random_uuid(),
    username text not null,
    created_at timestamp default now(),
    updated_at timestamp default now(),
    constraint pk_user primary key (id)
);
create unique index uniq_idx_user_username on app_public."user"(username);

create table app_public.group (
    id uuid default gen_random_uuid(),
    owner_id uuid not null,
    name text not null,
    created_at timestamp default now(),
    updated_at timestamp default now(),
    constraint pk_group primary key (id),
    constraint fk_group_owner_id foreign key (owner_id) references app_public."user"(id)
);
create unique index uniq_idx_group_owner_id_name on app_public."group"(owner_id, name);

create table app_public.membership (
    id uuid default gen_random_uuid(),
    user_id uuid not null,
    group_id uuid not null,
    constraint pk_membership primary key (id),
    constraint fk_membership_user_id foreign key (user_id) references app_public."user"(id),
    constraint fk_membership_group_id foreign key (group_id) references app_public.group(id)
);
create unique index uniq_idx_membership_group_id_user_id on app_public.membership(group_id, user_id);


create table app_public.folder (
    id uuid default gen_random_uuid(),
    group_id uuid not null,
    name text not null,
    created_at timestamp default now(),
    updated_at timestamp default now(),
    constraint pk_folder primary key (id),
    constraint fk_folder_group_id foreign key (group_id) references app_public.group(id)
);
create unique index uniq_idx_folder_group_id_name on app_public.folder(group_id, name);

create table app_public.document (
    id uuid default gen_random_uuid(),
    folder_id uuid not null,
    owner_id uuid not null,
    name text not null,
    body text,
    created_at timestamp default now(),
    updated_at timestamp default now(),
    constraint pk_document primary key (id),
    constraint fk_document_folder_id foreign key (folder_id) references app_public.folder(id),
    constraint fk_document_owner_id foreign key (owner_id) references app_public."user"(id)
);
create unique index uniq_idx_document_folder_id_name on app_public.document(folder_id, name);

create table app_public.execution (
    id uuid not null default gen_random_uuid(),
    document_id uuid not null,
    result jsonb not null,
    executed_at timestamp not null default now(),
    constraint pk_execution primary key (id),
    constraint fk_execution_document_id foreign key (document_id) references app_public.document(id)
);

create function app_private.set_updated_at() returns trigger as $$
begin
  new.updated_at := current_timestamp;
  return new;
end;
$$ language plpgsql;

create trigger user_updated_at before update
  on app_public."user"
  for each row
  execute procedure app_private.set_updated_at();

create trigger group_updated_at before update
  on app_public.group
  for each row
  execute procedure app_private.set_updated_at();

create trigger folder_updated_at before update
  on app_public.folder
  for each row
  execute procedure app_private.set_updated_at();

create trigger document_updated_at before update
  on app_public.folder
  for each row
  execute procedure app_private.set_updated_at();

create table app_private.user_account (
    user_id uuid,
    username text not null,
    password text not null,
    constraint pk_user_account primary key (user_id),
    constraint fk_user_account_user_id foreign key (user_id) references app_public."user"(id)
);
create unique index uniq_idx_user_account_username on app_private.user_account(username);

alter default privileges revoke execute on functions from public;

grant usage on schema app_public to app_anonymous, app_user;

grant select on table app_public."user" to app_anonymous, app_user;
grant update, delete on table app_public."user" to app_user;

grant select, insert, update, delete on table app_public.group to app_user;
grant select, insert, update, delete on table app_public.membership to app_user;
grant select, insert, update, delete on table app_public.folder to app_user;
grant select, insert, update, delete on table app_public.document to app_user;
grant select, insert, update, delete on table app_public.execution to app_user;

create function app_public.register(
    username text,
    password text
)
returns app_public."user"
as $$
declare
    "user" app_public."user";
begin
    insert into app_public."user"(username)
    values (register.username)
    returning * into "user";

    insert into app_private.user_account(user_id, username, password)
    values ("user".id, "user".username, crypt(register.password, gen_salt('bf', 8)));

    return "user";
end
$$ language plpgsql strict security definer;

create type app_public.jwt_token as (
    role text,
    user_id uuid,
    exp bigint
);

create or replace function app_public.authenticate(
    username text,
    password text
)
returns app_public.jwt_token
as $$
declare
    "user" app_private.user_account;
begin
    select u.* into "user"
    from app_private.user_account as u
    where u.username = authenticate.username;

    if "user".password = crypt(authenticate.password, "user".password) then
        return ('app_user',
                "user".user_id,
                extract(epoch from (now() + interval '2 days')))::app_public.jwt_token;
    else
        return null;
    end if;
end;
$$ language plpgsql strict security definer;

create function app_public.current_person()
returns app_public."user"
as $$
  select *
  from app_public."user"
  where id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
$$ language sql stable;

create or replace function app_public.add_group(
    user_id uuid,
    name text
)
returns table (group_id uuid, group_name text)
volatile
as $$
begin
    if (select exists(select g.id
                        from app_public."group" g
                        where g.owner_id = $1
                          and g.name = $2))
    then
        raise exception 'user already has group with this name';
    else
        return query (
            with insert_group as (
                insert into app_public.group (owner_id, name) values ($1, $2)
                    returning id
            ),
            insert_membership as (
                insert into app_public.membership (group_id, user_id)
                    select id, $1 from insert_group
                    returning membership.group_id, membership.user_id
            )
            select im.group_id,
                   $2
            from insert_membership im
        );
    end if;
end
$$ language plpgsql strict security definer;

create or replace function app_public.delete_user_group(
    group_id uuid
)
returns void
as $$
begin
    delete from app_public.membership where membership.group_id = $1;
    delete from app_public.group where id = $1;
end
$$ language plpgsql;

grant execute on function app_public.authenticate(text, text) to app_anonymous, app_user;
grant execute on function app_public.current_person() to app_anonymous, app_user;

grant execute on function app_public.register(text, text) to app_anonymous;

grant execute on function app_public.add_group(uuid, text) to app_user;
grant execute on function app_public.delete_user_group(uuid) to app_user;

alter table app_public."user" enable row level security;
alter table app_public.group enable row level security;
alter table app_public.membership enable row level security;
alter table app_public.folder enable row level security;
alter table app_public.document enable row level security;

create policy select_user on app_public."user" for select
    using (id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid);
create policy update_user on app_public."user" for update to app_user
    using (id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid);
create policy delete_user on app_public."user" for delete to app_user
    using (id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid);

create policy select_group on app_public.group for select to app_user
    using (
        id in (
            select group_id
            from app_public.membership
            where user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid)
    );
create policy insert_group on app_public.group for insert to app_user
    with check (owner_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid);
create policy update_group on app_public.group for update to app_user
    using (owner_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid);
create policy delete_group on app_public.group for delete to app_user
    using (owner_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid);

create policy select_membership on app_public.membership for select to app_user
    using (user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid);
create policy insert_membership on app_public.membership for insert to app_user
    with check (user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid);
-- create policy update_membership on app_public.membership for update to app_user
--     using (user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid);
create policy delete_membership on app_public.membership for delete to app_user
    using (user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid);

create policy select_folder on app_public.folder for select to app_user
    using (
        group_id in (
            select group_id from app_public.membership
            where user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );
create policy insert_folder on app_public.folder for insert to app_user
    with check (
        group_id in (
            select group_id from app_public.membership
            where user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );
create policy update_folder on app_public.folder for update to app_user
    using (
        group_id in (
            select group_id from app_public.membership
            where user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );
create policy delete_folder on app_public.folder for delete to app_user
    using (
        group_id in (
            select group_id from app_public.membership
            where user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );

create policy select_document on app_public.document for select to app_user
    using (
        owner_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        or
        folder_id in (
            select f.id from app_public.folder f
            join app_public.membership m on f.group_id = m.group_id
            where m.user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );
create policy insert_document on app_public.document for insert to app_user
    with check (
        owner_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        and
        folder_id in (
            select f.id from app_public.folder f
            join app_public.membership m on f.group_id = m.group_id
            where m.user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );
create policy update_document on app_public.document for update to app_user
    using (
        owner_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        or
        folder_id in (
            select f.id from app_public.folder f
            join app_public.membership m on f.group_id = m.group_id
            where m.user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );
create policy delete_document on app_public.document for delete to app_user
    using (
        owner_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        and
        folder_id in (
            select f.id from app_public.folder f
            join app_public.membership m on f.group_id = m.group_id
            where m.user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );

create policy select_execution on app_public.execution for select to app_user
    using (
        id in (
            select d.id from app_public.document d
            join app_public.folder f on d.folder_id = f.id
            join app_public.membership m on f.group_id = m.group_id
            where m.user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );
create policy insert_execution on app_public.execution for insert to app_user
    with check (
        id in (
            select d.id from app_public.document d
            join app_public.folder f on d.folder_id = f.id
            join app_public.membership m on f.group_id = m.group_id
            where m.user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );
create policy delete_execution on app_public.execution for delete to app_user
    using (
        id in (
            select d.id from app_public.document d
            join app_public.folder f on d.folder_id = f.id
            join app_public.membership m on f.group_id = m.group_id
            where m.user_id = nullif(current_setting('jwt.claims.user_id', true), '')::uuid
        )
    );
