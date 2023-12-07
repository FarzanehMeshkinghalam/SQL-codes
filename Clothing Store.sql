/*1.Basic stats on customers per city for a specific time period*/
select distinct concat(c.customer_fname,'',c.customer_lname) Customer_Fullname, a.Customer_DOB DOB,
                a.Customer_Email Email, c.Customer_Phone Phone,b.branch_city City
from orders o, branch b,customer c
left join account_info a
on c.customer_id = a.customer_id
where c.customer_id = o.customer_id
  and b.branch_id = o.branch_id
  and o.order_date between '2022-09-01' and '2022-10-31'
  order by b.branch_city;


/*2.All products with description and prices*/
select p.Product_Name NameOfProduct,p.Product_Size Size ,p.Product_Color Color,
       p.Product_Description Description ,p.Product_Composition Composition,
       p.Product_Inventory Inventory, p.Product_Price Price, g.Category_Name
from product p, Categories g
where g.category_id = p.category_id;


/*3.Order record and delivery details.*/
select distinct o.Order_no,
       CASE WHEN o.Order_Is_Online = 'T' THEN 'Yes' ELSE 'No' END AS Is_Online ,
       o.Order_Date,o.Order_Time,
       o.Order_Status delivery, o.Transaction_Status
from orders o
order by o.Order_no ;


/*4.Report of product availability and their location*/
select  p.Product_Name,b.branch_name, pb.pro_bra_Inventory  Inventory
from Product_Branch pb, branch b, product p
where pb.branch_id = b.branch_id
  and pb.Product_ID = p.Product_ID;

/*5.Monthly income generated per city/location*/
select b.branch_name,sum(s.Order_Quantity*s.Unit_Price) city_income
from branch b,orders o,Sales s
where b.branch_id = o.branch_id
  and o.order_id = s.order_id
group by b.branch_name
order by city_income desc;


/*Total Amount per order */
select o.Order_no Order_number,
      concat(c.customer_fname,'',c.customer_lname) Customer_Fullname,
      sum(s.Order_Quantity*s.Unit_Price) total_Amount
from Orders o ,Sales s , customer c
where o.order_id = s.order_id
  and o.customer_id = c.customer_id
  and (o.Transaction_Status <> 'Refunded' or o.Order_Status <> 'Canceled')
group by Order_number,Customer_Fullname
order by Total_amount desc;


/*Customer_point*/
select o.customer_id,concat(c.customer_fname,'',c.customer_lname) Customer_Fullname,
       round(sum(s.Unit_Price*s.Order_Quantity)/10,0) Order_Point
from orders o, Sales s ,customer c
where s.order_id = o.Order_ID and c.customer_id = o.customer_id
      and (o.Transaction_Status <> 'Refunded' or o.Order_Status <> 'Canceled')

group by o.customer_id,Customer_Fullname
order by Order_Point desc;
