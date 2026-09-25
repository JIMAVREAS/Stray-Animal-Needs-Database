-- Display all needs that have not yet been covered, including the organisation name and the required amount.
select "organisation", "amount"
from "uncovered_needs";

--Display all covered needs
select *
from "covered_needs";

--Find all customers who have covered at least one need and display how many needs each customer has covered
select "first_name", "last_name", count(*) as "needs_covered"
from "covered_needs"
group by "first_name", "last_name";

--Find uncovered needs whose amount is greater than the average amount of all needs
select "organisation", "message", "amount"
from "uncovered_needs"
where "amount" > (
    select avg("amount")
    from "needs"
);


--Find customers who have never covered a need
select "first_name", "last_name"
from "customers"
where not exists (
    select 1
    from "customer_covers_needs"
    where "customer_covers_needs"."customer_id" = "customers"."id"
);

--Find all needs belonging to each organisation.
select "organisations"."name", "needs"."message", "needs"."amount"
from "organisations"
join "needs"  on "organisations"."id" = "needs"."org_id";

--Find the three customers who have covered the largest total amount of needs.
select"customers"."first_name", "customers"."last_name", sum("needs"."amount") as "total_amount"
from "customers"
join "customer_covers_needs" on "customers"."id" = "customer_covers_needs"."customer_id"
join "needs" on "customer_covers_needs"."need_id" = "needs"."id"
group by "customers"."id", "customers"."first_name", "customers"."last_name"
order by "total_amount" desc
limit 3;


-- Add a new need for an organisation.

insert into "needs" ("id", "message", "amount", "org_id")
values (101, 'Food for stray dogs', 150, 1);


-- Record that a customer has covered a need.
-- This also activates the trigger that updates the organisation balance.

insert into "customer_covers_needs" ("customer_id", "need_id")
values (1, 101);


-- Update the message and amount of an uncovered need.

update "needs"
set "message" = 'Food and medicine for stray dogs',
    "amount" = 200
where "id" = 101;


-- Delete a need that is no longer required.

delete from "needs"
where "id" = 101;
