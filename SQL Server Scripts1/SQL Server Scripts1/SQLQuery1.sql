drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 
INSERT INTO goldusers_signup(userid,gold_signup_date) 
VALUES (1,'09-22-2017'),(3,'04-21-2017');
drop table if exists users;

CREATE TABLE users(userid integer,signup_date date); 
INSERT INTO users(userid,signup_date) 
VALUES (1,'09-02-2014'),(2,'01-15-2015'),(3,'04-11-2014');
drop table if exists sales;

CREATE TABLE sales(userid integer,created_date date,product_id integer); 
INSERT INTO sales(userid,created_date,product_id) 
VALUES (1,'04-19-2017',2),(3,'12-18-2019',1),(2,'07-20-2020',3),(1,'10-23-2019',2),(1,'03-19-2018',3),(3,'12-20-2016',2),(1,'11-09-2016',1),(1,'05-20-2016',3),(2,'09-24-2017',1),(1,'03-11-2017',2),(1,'03-11-2016',1),(3,'11-10-2016',1),(3,'12-07-2017',2),(3,'12-15-2016',2),(2,'11-08-2017',2),(2,'09-10-2018',3);
drop table if exists product;

CREATE TABLE product(product_id integer,product_name text,price integer); 
INSERT INTO product(product_id,product_name,price) 
VALUES(1,'p1',980),(2,'p2',870),(3,'p3',330);
select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- 1. total amount each customer spend on zomoto?

select s.userid , sum(p.price) as total_spent
from sales s 
inner join product p
on s.product_id = p.product_id
group by s.userid
;

-- 2. how many days each customer visited zomato?

select userid, count(distinct created_date) as visited_date
from sales
group by userid
;
-- 3. What was the first product purchased by each customer?

select*,rank()over(partition by userid order by created_date) rnk from sales -- show all rank 
select * from
(select*,rank()over(partition by userid order by created_date) rnk from sales)s 
where rnk = 1
;
-- 4. What is the most purchased item on the menu 
-- And how many times was it purchased by all customer?

select userid,count(product_id) as total_purchased
from sales where product_id = ( 
select top 1 product_id 
from sales
group by product_id
order by count(product_id)desc
)
group by userid 
;

-- show most sell of product

select product_id,count(product_id) as most_purchased  
from sales
group by product_id
order by most_purchased desc  
; 

-- 5. Which item is most popular in each customer?

select * from 
(select *, rank() over(partition by userid 
order by cnt desc) rnk
from 
(select userid, product_id as fav_product, count(product_id) cnt
from sales
group by userid,product_id)a)b
where rnk=1
;

-- 6. Which item was purchased first by the customer 
--after they became a member -gold ?

select * 
from
(select c.*,rank() over(partition by userid 
order by created_date) rnk_date
from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date
from sales s 
inner join goldusers_signup g
on s.userid = g.userid
where created_date>=gold_signup_date)c)d
where rnk_date = 1 
;

-- 7. Which item was purchased 
--just before the customer became a member-gold?
select*
from
(select a.*, rank() over(partition by userid
order by created_date desc) rnk_last_order
from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date
from sales s
inner join goldusers_signup g
on s.userid = g.userid
where s.created_date<=g.gold_signup_date)a)b
where rnk_last_order = 1
;

-- 8. What is the total orders and amount spent for each member
--before they become a member-gold? 

select userid, count(created_date) as total_product,sum(price) as total_amount
from(
select a.*,p.price from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date
from sales s
inner join goldusers_signup g
on s.userid = g.userid
where s.created_date<=g.gold_signup_date)a
inner join product p
on a.product_id = p.product_id)b
group by userid
;

--total order
select userid, count(product_id) as total_order
from sales
group by userid
;
--amount spent by each customer on each product
select s.userid,p.product_id,sum(p.price) as total_price
from sales s
inner join product p
on s.product_id = p.product_id
group by s.userid ,p.product_id
;

-- 9. If buying each product generates Zomato points, eg: 5rs=2 
--and each product has different purchasinng points, eg: 
--for prooduct1 5rs=1 Zomato point, 
--for product2 10rs=5 Zomato point,
--and pproduct3 5rs=1 Zomato point 

-- Q. calculate points collected by each customers 
--and for which product most points have been given till now.
-- (2 rs = 1 Zomato point)

select b.*,total_amt/points as total_points 
from
(select a.*,
  case 
     when product_id = 1 then 5
     when product_id = 2 then 2
     when product_id = 3 then 5
  else 0 end
as points 
from
(select s.userid,p.product_id,sum(p.price) as total_amt
from sales s
inner join product p
on s.product_id = p.product_id
group by s.userid ,p.product_id)a)b
;

-- 1st part:calculate points collected by each customers 
--          mult with 2.5 to get total number of rp earned by each of the customer

select userid,sum(total_points)*2.5 as cashback_or_points
from
(select b.*,total_amt/points as total_points 
from
(select a.*,
  case 
     when product_id = 1 then 5
     when product_id = 2 then 2
     when product_id = 3 then 5
  else 0 end
as points 
from
(select s.userid,p.product_id,sum(p.price) as total_amt
from sales s
inner join product p
on s.product_id = p.product_id
group by s.userid ,p.product_id)a)b)c
group by userid
;

-- 2nd part: which product most points have been given till now

select * 
from
(select * , rank() over(order by earn_points desc) rnk 
from
(select product_id,sum(total_points) as earn_points
from
(select b.*,total_amt/points as total_points 
from
(select a.*,
  case 
     when product_id = 1 then 5
     when product_id = 2 then 2
     when product_id = 3 then 5
  else 0 end
as points 
from
(select s.userid,p.product_id,sum(p.price) as total_amt
from sales s
inner join product p
on s.product_id = p.product_id
group by s.userid ,p.product_id)a)b)c
group by product_id)d)e
where rnk = 1
;

-- 10. In the first one year after a customer joins the gold program (including their join date)
--irrespective of what the customer has purchased they earn 5 Zomato points for every 10 rs spent
--who earned more 1 or 3 and what was their points earnings in their first year? 
-- where(1zp =2rs and  0.5zp = 1rs)

select a.*, p.price*0.5 as total_points_earn
from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date
from sales s 
inner join goldusers_signup g
on s.userid = g.userid
where created_date >= gold_signup_date 
and created_date <= dateadd(year,1,gold_signup_date))a
inner join product p
on a.product_id = p.product_id
;

-- 11. Rank all the transaction of the customers

select *, rank() over(partition by userid order by created_date) as rnk from sales ;

-- 12. Rank all the transaction for each member 
--whenever they are a Zomato gold member 
--for every non gold memeber transction mark as na

select s.userid,s.created_date,s.product_id,g.gold_signup_date 
from sales s
left join goldusers_signup g 
on s.userid = g.userid
and created_date >= gold_signup_date
;


-- cast is used to change data type 

select b.*, case when gold_member=0 then'NA' else gold_member end as rnk
from
(select a.*, 
cast(
     (
	   case 
           when gold_signup_date is null then 0
	   else
	       rank() over(partition by userid order by created_date desc) 
	   end
	 ) as varchar
	) 
as gold_member
from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date 
from sales s
left join goldusers_signup g 
on s.userid = g.userid
and created_date >= gold_signup_date)a)b
;