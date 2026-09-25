--creation of the users table
create table "users"
(
    "id" integer not null,
    "username" text  unique not null,
    "password" text not null,
    "role"  text not null check("role" in ('organisation','customer')),
    "email" text unique not null,
    primary key("id")
);

--creation of the organisations table
create table "organisations"
(
    "id" integer not null,
    "name" text not null,
    "user_id" integer not null unique,
    "balance" numeric not null default 0 check("balance" >=0),
    primary key("id"),
    foreign key("user_id") references "users"("id")
    on delete cascade
);

--creation of the needs table
create table "needs"
(
    "id" integer not null,
    "message" text not null,
    "amount" numeric not null check("amount" > 0),
    "org_id" integer not null,
    primary key("id"),
    foreign key("org_id") references "organisations"("id")
    on delete cascade
);

--creation of the customers table
create table "customers"
(
    "id" integer not null,
    "first_name" text not null,
    "last_name" text not null,
    "user_id" integer not null unique,
    primary key("id"),
    foreign key("user_id") references "users"("id")
    on delete cascade
);

--creation  of customer_covers_needs table
create table "customer_covers_needs"
(
    "customer_id" integer not null,
    "need_id" integer not null,
    "covered_at" text not null default current_timestamp,
    primary key("need_id"),
    foreign key("customer_id") references "customers"("id")
    on delete cascade,
    foreign key("need_id") references "needs"("id")
    on delete cascade
);

--indexing to optimize the queries

create index "needs_org_index" on "needs" ("org_id");
create index "covers_customer_index" on "customer_covers_needs" ("customer_id");


--view for uncovered needs
create view  "uncovered_needs"  as
select "needs"."id", "needs"."message", "needs"."amount", "organisations"."name"
from "needs"
join "organisations" on "needs"."org_id"="organisations"."id"
where not exists ( select 1
                   from "customer_covers_needs"
                   where "customer_covers_needs"."need_id"="needs"."id");


--view for the covered needs
create view "covered_needs" as
select
    "customers"."first_name",
    "customers"."last_name",
    "organisations"."name" as "organisation",
    "needs"."message",
    "needs"."amount",
    "customer_covers_needs"."covered_at"
from "customer_covers_needs"
join "customers"
    on "customer_covers_needs"."customer_id" = "customers"."id"
join "needs"
    on "customer_covers_needs"."need_id" = "needs"."id"
join "organisations"
    on "needs"."org_id" = "organisations"."id";


--view for the state of each organisation
create view "organisation_statistics" as
select "organisations"."id",
       "organisations"."name",
       count("needs"."id") as "total_needs",
       sum(
          case
              when "customer_covers_needs"."need_id" is not null then 1
              else 0
         end
       ) as "covered_needs"
from "organisations"
left join "needs" on "organisations"."id"="needs"."org_id"
left join "customer_covers_needs" on "needs"."id"="customer_covers_needs"."need_id"
group by "organisations"."id";


-- trigger to update the organisation balance
-- when a need is covered

create trigger "update_organisation_balance"
after insert on "customer_covers_needs"
for each row
begin
    update "organisations"
    set "balance" = "balance" + (
        select "amount"
        from "needs"
        where "id" = new."need_id"
    )
    where "id" = (
        select "org_id"
        from "needs"
        where "id" = new."need_id"
    );
end;

