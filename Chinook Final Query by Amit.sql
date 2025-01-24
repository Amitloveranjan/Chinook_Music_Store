use chinook;

								-- Objective Questions --
	-- Q.1) Does any table have missing values or duplicates? If yes how would you handle it ?
select * from album;
select distinct * from album;  -- no duplicate

select * from artist;
select distinct * from artist; -- no duplicate

select * from customer;
select distinct * from customer; -- no duplicate

select count(*) from customer
where company is null; -- count of null in company 49

select count(*) from customer
where state is null;  -- count of null in state 29

select count(*) from customer
where fax is null;  -- count of null in fax 47

select * from employee; -- there is 1 null value in report_to for employee_id = 1
select distinct * from employee;  -- no duplicate

select * from genre;
select distinct * from genre; -- no duplicate

select * from invoice;
select distinct * from invoice; -- no duplicate

select * from invoice_line;
select distinct * from invoice_line; -- no duplicate

select * from media_type;
select distinct * from media_type; -- no duplicate

select * from playlist;
select distinct * from playlist; -- no duplicate

select * from playlist_track;
select distinct * from playlist_track; -- no duplicate

select * from track;
select distinct * from track; -- no duplicate
select count(*) from track
where composer is null; --  978 null value in composer

/* There are no duplicate value in any table of whole dataset
some null value are found, I will use 'COALESCE' to handle null values
*/
  -- ***************************************************************************************************** --
  
	-- Q.2)	Find the top-selling tracks and top artist in the USA and identify their most famous genres.
        
select Top_selling_tracks , Top_artist , Most_famous_genres     
from ( 
	select t.name as Top_selling_tracks , ar.name as Top_artist , g.name as Most_famous_genres ,
           sum(t.unit_price * il.quantity) as total_sales from track t
    left join  invoice_line il on t.track_id = il.track_id
    left join invoice i on i.invoice_id = il.invoice_id
    left join album a on a.album_id = t.album_id
    left join artist ar on ar.artist_id = a.artist_id
    left join genre g on g.genre_id = t.genre_id
    where billing_country = "USA"
    group by t.name , ar.name , g.name
    order by total_sales desc
    limit 15
      )   Top_Track_Artist_Genre;


-- For top selling genre 

select Top_Genre from ( 
		select g.name as Top_Genre
		from track t
		left join invoice_line il on il.track_id = t.track_id
		left join invoice i on i.invoice_id = il.invoice_id
		left join genre g on t.genre_id = g.genre_id
		where i.billing_country = 'USA'
		group by g.name
		order by sum(il.quantity) desc
		limit 15 ) Most_Famous_genre;


		-- ***************************************************************************************************** --               
        
	-- Q.3)	What is the customer demographic breakdown (age, gender, location) of Chinook's customer base? --
	
select count(distinct country) from customer ;    -- total country 24
select country , count(customer_id) as  customer_count
	from customer
group by country 
order by customer_count desc;                 
       
    -- USA : 13 , Canada : 8 , Brazil : 5 , France : 5 , Germany : 4 , United Kingdom : 3 ,  
    -- Czech Republic : 2 , Pourtgal : 2, India :2 , and from remaining all country 1 customer each

/*
 The customer base of Chinook music store is across 24 countries. According to our data USA is the country with most number of customers 13.
 age and gender not available in given customer table columns to understand the customer breakdown.
*/       
		-- ***************************************************************************************************** -- 
       
	-- Q.4)	Calculate the total revenue and number of invoices for each country, state, and city:

select billing_country , billing_state , billing_city , count(*) as number_of_invoice , sum(total) as total_revenue
from invoice
group by billing_country , billing_state , billing_city
order by number_of_invoice desc , total_revenue desc;

		-- ***************************************************************************************************** -- 
        
	-- Q.5)	Find the top 5 customers by total revenue in each country

with customer_wise_total_revenue as (
select customer_id , sum(total) as total_revenue
from invoice
group by customer_id ) , 
Customer_ranking as (
select concat(c.first_name , ' ' , c.last_name) as Customer_Name , c.country ,
dense_rank() over (partition by c.country order by cr.total_revenue desc) as ranking
from customer c
right join customer_wise_total_revenue cr on cr.customer_id = c.customer_id)
select Customer_name, country, ranking from Customer_ranking where ranking <=5
order by country;



		-- ***************************************************************************************************** -- 
        
	-- Q.6)	Identify the top-selling track for each customer

with Top_selling_Rank as (select c.customer_id, concat(c.first_name, ' ', c.last_name) as customer_name,  
						t.name as track_name,  sum(il.quantity) as total_sales, 
                        row_number() over (partition by c.customer_id order by sum(il.quantity) desc) as ranking
			from customer c
			left join invoice i on i.customer_id = c.customer_id
			left join invoice_line il on i.invoice_id = il.invoice_id
			left join track t on il.track_id = t.track_id
			group by c.customer_id, concat(c.first_name, ' ', c.last_name), t.name)
select customer_name,  track_name, total_sales 
from  Top_selling_Rank 
where  ranking = 1;

-- Top selling track for each customer grouping by customer_id , customer_name and track_name 
    

 

 
		-- ***************************************************************************************************** --     
    
	-- Q.7)	Are there any patterns or trends in customer purchasing behavior 
    -- (e.g., frequency of purchases, preferred payment methods, average order value)?

select customer_id , round(avg(total),2) as average_total_value , count(invoice_id) as number_of_ordder
from invoice
group by customer_id
order by count(invoice_id) ;

select count(invoice_id) as monthly_invoice_count , date_format(invoice_date , '%m-%Y') as Month_Year ,
		round(avg(total),2) as Monthly_average_total , sum(total) as Monthly_sum_total
from invoice
group by Month_Year 
order by Month_Year;
    
		-- ***************************************************************************************************** --     
    
	-- Q.8)	What is the customer churn rate?


with number_of_customer_in_1st_3months as (
		select count(customer_id) as customer_1st_3months
        from invoice
        where invoice_date between '2017-01-01' and '2017-03-31'
        ) ,

-- I have taken the assumption that total number of customers in the beginning is equal to the customers joining in the first 3 months.
 -- 49 customer in 1st 3 months

number_of_customer_in_last_2months as (select count(customer_id) as customer_in_last_2months
        from invoice
        where invoice_date between '2020-11-01' and '2020-12-31' )

 -- I have taken the assumption that churn rate will be calculated on the basis of the number of customers left in the last two months.
 -- 29 customer in last 2 months

select round((((select customer_1st_3months from number_of_customer_in_1st_3months) - (select customer_in_last_2months 
			from number_of_customer_in_last_2months))/(select customer_1st_3months 
            from number_of_customer_in_1st_3months)* 100),2) as churn_rate;

/* 
As per given data the customer churn rate of the company is 40.82% based on the total number of customer 
in first 3 months is 49 and the number of customer present in the last 2 months is 29
So, number of customers lost = 49-29 = 20 , churn rate = (49-29)/49 * 100 
*/ 

    
		-- ***************************************************************************************************** --     
    
	-- Q.9)	Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.


with Total_USA_Revenue as ( select sum(total) as total_rev
							from invoice
                            where billing_country = 'USA' ),
Genre_wise_total_revenue as ( select g.name as genre_name, sum(t.unit_price * il.quantity) as total_genre_revenue
                              from genre g
							  right join track t on g.genre_id = t.genre_id
							  left join invoice_line il on il.track_id = t.track_id
							  left join invoice i on i.invoice_id = il.invoice_id
							  where billing_country = 'USA'
							  group by g.name 
							  order by total_genre_revenue desc ),
Genre_Ranking as ( select genre_name, round(total_genre_revenue *100/(select total_rev from Total_USA_Revenue),2) percentage_contribution,
             dense_rank() over(order by round(total_genre_revenue *100/(select total_rev from Total_USA_Revenue),2) desc) Ranking
             from Genre_wise_total_revenue )
             
select genre_name, percentage_contribution, Ranking from Genre_Ranking ;

-- Best selling genre
/* genre_name, percentage_contribution, Ranking
	Rock				53.38	1
	Alternative & Punk	12.37	2
	Metal				11.80	3
	R&B/Soul			5.04	4
	Blues				3.43	5
	Alternative			3.33	6
	Latin				2.09	7
	Pop					2.09	7
	Hip Hop/Rap			1.90	8
	Jazz				1.33	9
	Easy Listening		1.24	10
	Reggae				0.57	11
	Electronica/Dance	0.48	12
	Classical			0.38	13
	Heavy Metal			0.29	14
	TV Shows			0.19	15
	Soundtrack			0.19	15
*/

-- Best selling Artist wise

with Total_USA_Revenue as ( select sum(total) as total_rev
							from invoice
                            where billing_country = 'USA' ),
Artist_wise_total_revenue as ( select a.name as Artist_name, sum(t.unit_price * il.quantity) as total_revenue_Artist_wise
                              from artist a
                              left join album al on a.artist_id = al.artist_id
							  right join track t on al.album_id = t.album_id
							  left join invoice_line il on il.track_id = t.track_id
							  left join invoice i on i.invoice_id = il.invoice_id
							  where billing_country = 'USA'
							  group by a.name 
							  order by total_revenue_Artist_wise desc ),
Artist_Ranking as ( select Artist_name, round(total_revenue_Artist_wise *100/(select total_rev from Total_USA_Revenue),2) percentage_contribution,
             dense_rank() over(order by round(total_revenue_Artist_wise *100/(select total_rev from Total_USA_Revenue),2) desc) Ranking
             from Artist_wise_total_revenue )
             
select Artist_name, percentage_contribution, Ranking 
from Artist_Ranking
limit 10 ;

 -- Top 10 selling Artist wise
/* 	Artist_name, percentage_contribution, Ranking 
	Van Halen			4.09	1
	R.E.M.				3.62	2
	The Rolling Stones	3.52	3
	Nirvana				3.33	4
	Foo Fighters		3.24	5
	Eric Clapton		3.24	5
	Guns N' Roses		3.04	6
	Green Day			3.04	6
	Pearl Jam			2.95	7
	Amy Winehouse		2.85	8

 */
		-- ***************************************************************************************************** --     
    
	-- Q.10)	Find customers who have purchased tracks from at least 3 different genres

select Customer_Name , Total 
from ( select concat(first_name, ' ', last_name) as Customer_Name , count(distinct g.name) as Total
        from customer c
        left join invoice i on i.customer_id = c.customer_id
        left join invoice_line il on il.invoice_id = i.invoice_id
        left join track t on t.track_id = il.track_id
        left join genre g on g.genre_id = t.genre_id
        group by 1
        having count(distinct g.name) >= 3
        order by count(distinct g.name) desc
        ) as Customer_Total_Purchase ;

    
		-- ***************************************************************************************************** --     
    
	-- Q.11)	Rank genres based on their sales performance in the USA

with Sales_Genre as (
				select t.genre_id , g.name , sum(t.unit_price * il.quantity) sales_performance 
                from track t
                left join genre g on g.genre_id = t.genre_id
                left join invoice_line il on il.track_id = t.track_id
                left join invoice i on i.invoice_id = il.invoice_id
                where billing_country = 'USA'
                group by 1, 2 )
select name , sales_performance , 
       dense_rank() over (order by sales_performance desc) `Rank` 
       from Sales_Genre;


    
		-- ***************************************************************************************************** --     
    
	-- Q.12)	Identify customers who have not made a purchase in the last 3 months
	
select c.customer_id , concat(c.first_name , ' ' , c.last_name) as customer_name
from customer c
where c.customer_id not in (
							select distinct i.customer_id
                            from invoice i 
                            where i.invoice_date >= date_sub('2020-12-31', interval 3 month ) );

    
		-- ***************************************************************************************************** --     
        
										-- Subjective Questions 
	-- Q.1)	Recommend the three albums from the new record label that should be prioritised for advertising and promotion in the USA
    --      based on genre sales analysis.
    
select * from track 
order by album_id , genre_id ; 
select genre_id , name from genre ; 

with Sales as ( select g.name as genre_name, sum(il.quantity * il.unit_price) as total_sales 
    from invoice i
    join invoice_line il on i.invoice_id = il.invoice_id 
    join track t on il.track_id = t.track_id 
    join genre g on t.genre_id = g.genre_id
    where i.billing_country = 'usa' 
    group by g.name 
    order by  total_sales desc ),
Top_Albums as ( select al.title as album_title, ar.name as artist_name, g.name as genre_name, sum(il.quantity * il.unit_price) as album_sales
    from invoice i 
    join invoice_line il on i.invoice_id = il.invoice_id 
    join track t on il.track_id = t.track_id
    join album al on t.album_id = al.album_id 
    join artist ar on al.artist_id = ar.artist_id 
    join genre g on t.genre_id = g.genre_id
    where i.billing_country = 'USA' 
    group by al.title, ar.name, g.name 
    order by album_sales desc )
select album_title, artist_name, genre_name, album_sales 
from Top_Albums 
limit 3;


/*
Following albums should be prioritised for advertisement and promotion:
 album_title 									artist_name 	 genre_name
From The Muddy Banks Of The Wishkah [live]		Nirvana		   	 Rock	
Are You Experienced?							Jimi Hendrix	 Rock	
The Doors										The Doors		 Rock	
*/


    
    
		-- ***************************************************************************************************** --     
    
	-- Q.2)	Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.

select g.genre_id , g.name , coalesce(sum(t.unit_price * il.quantity),0) as Total_Revenue_Each_Genre
from track t
left join genre g on g.genre_id = t.genre_id
left join invoice_line il on il.track_id = t.track_id
left join invoice i on i.invoice_id = t.track_id
where billing_country != 'USA'
group by 1,2
order by Total_Revenue_Each_Genre desc ;


/* Rock genre is on Top , 
Metal is 2nd & Alternative and Punk on 3rd.
*/



		-- ***************************************************************************************************** -- 

	-- Q.3)	Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, spending amount) of long-term 
    --      customers differ from those of new customers? What insights can these patterns provide about customer loyalty and retention strategies?

with Purchase_freq as ( select i.customer_id , max(invoice_date) , min(invoice_date) ,
		abs(timestampdiff(month , max(invoice_date) , min(invoice_date))) as each_cust_time ,
        sum(total) as sales , sum(quantity) as item_count , count(invoice_date) as frequency
        from invoice i 
        left join customer c on c.customer_id = i.customer_id
        left join invoice_line il on il.invoice_id = i.invoice_id
        group by i.customer_id
		order by each_cust_time desc ) ,
 
 average_time as ( select round(avg(each_cust_time),2) as average
				 from Purchase_freq ) ,  -- 40.36 Months

Category_Define as (select * , case
								when each_cust_time > ( select average from average_time)
                                     then "Long-term Customer" else "Short-term Customer"
                                     end as category
					from Purchase_freq )
select category , sum(sales) as Total_spent , sum(item_count) as basket_size , count(frequency) as frequency
from Category_Define
group by category ;

/*
Insights:
Long-term customers tend to spend more, have larger basket sizes, and shop more frequently compared to short-term customers.

Recommendations:
The company should focus on offering a wider variety of genres tailored to the preferences of long-term customers. 
These customers contribute significantly more revenue, as loyalty plays a crucial role in driving sales. 
Building and nurturing relationships with long-term customers is key, as they tend to make more purchases 
over time compared to short-term customers.

*/


		-- ***************************************************************************************************** -- 

	-- Q.4)	Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers? 
    --      How can this information guide product recommendations and cross-selling initiatives?

  -- ( select * from invoice_line ; )

					-- Purchase by customer over an invoice but different genre

select il.invoice_id , g.name
from invoice_line il
left join track t on t.track_id = il.track_id
left join genre g on g.genre_id = t.genre_id
group by 1 , 2 ;

					-- Different Artists prefered in single invoice
select il.invoice_id, ar.name
from invoice_line il 
left join track t on t.track_id = il.track_id
left join album a on a.album_id = t.album_id
left join artist ar on ar.artist_id = a.artist_id
group by 1 , 2 ;

				-- Different Albums purchased over an invoice
select il.invoice_id, al.title
from invoice_line il
left join track t on t.track_id = il.track_id
left join album al on al.album_id = t.album_id
group by 1 , 2 ;

		-- ***************************************************************************************************** -- 

	-- Q.5)	Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different geographic regions or store locations?
    --      How might these correlate with local demographic or economic factors?

with first_six_months as (select billing_country, count(customer_id) count_of_cust 
						  from invoice
						  where invoice_date between '2017-01-01' and '2017-06-30'
						  group by billing_country ),

last_six_months as ( select billing_country, count(customer_id) count_of_cust 
					 from invoice
				     where invoice_date between '2020-07-01' and '2020-12-31' 
					 group by billing_country )

select f6.billing_country, round((f6.count_of_cust - coalesce(l6.count_of_cust,0))/f6.count_of_cust * 100 , 2) churn_rate 
from first_six_months f6
left join  last_six_months l6 on f6.billing_country = l6.billing_country
order by churn_rate desc ;





		-- ***************************************************************************************************** -- 

	-- Q.6)	Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), which customer segments are more 
    --      likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk?


-- First trying to find customer  Days_Since_Last_Purchase

select customer_id , datediff('2020-12-31' , max(invoice_date)) as Days_Since_Last_Purchase
from invoice
group by customer_id;


 -- Assume a customer is at risk if they haven't purchased in the last 90 days.

with Risk_Status as ( select customer_id ,
case
	when datediff('2020-12-31' , max(invoice_date)) > 90 then 'At Risk' 
    else 'Active'
    end as Customer_Risk_Status    
from invoice
group by customer_id )

select Customer_Risk_Status , count(*) as Total_Count
from Risk_Status
group by Customer_Risk_Status;


-- Calculate Total Spending and Average Spending per Customer

select customer_id , count(invoice_id) as Total_Invoice ,
       sum(total) as Total_Spent , round(avg(total),2) as Avg_Spent_Per_invoice
from invoice
group by customer_id ;


-- Compare spending across year by year

select customer_id , year(invoice_date) as Year , sum(total) as Yearly_Spending
from invoice
group by customer_id, year(invoice_date)
order by customer_id, Year;


 -- Analyze Spending by Location (City , State and Country)
 
 select billing_city , billing_state , billing_country ,
        count(distinct customer_id) as Customer_Count , sum(total) as Total_Spent , round(avg(total),2) as Avg_Spent
from invoice
group by billing_city , billing_state , billing_country
order by total_spent desc ;



/*  Factors Contributing to Risk

    High Recency (Days Since Last Purchase): Customers who haven’t purchased in a long time.
    Low Frequency (Total Invoices): Customers with infrequent transactions.
    Declining Spending Trends: Customers whose spending decreases over time.
    Demographic Location: Customers in regions with lower average spending or higher churn.
*/    




		-- ***************************************************************************************************** -- 

	-- Q.7)	Customer Lifetime Value Modeling: How can you leverage customer data (tenure, purchase history, engagement) to predict the 
    --      lifetime value of different customer segments? This could inform targeted marketing and loyalty program strategies. 
    --      Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?

with purchase_history as ( select i.customer_id , i.billing_country , i.invoice_date ,
		concat(c.first_name , ' ' , c.last_name) as customer_name , i.total
        from invoice i
        left join customer c on i.customer_id = c.customer_id
        group by i.customer_id , i.billing_country , i.invoice_date , i.total
        order by customer_name ) ,

Lifetime_purchase as (select customer_id , sum(total) as Lifetime_value
					  from invoice
					  group by customer_id )

select ph.customer_id , ph.billing_country , ph.invoice_date ,
		ph.customer_name , ph.total , lp.Lifetime_value
        from purchase_history ph
        left join Lifetime_purchase lp on lp.customer_id = ph.customer_id
        order by lp.Lifetime_value desc , ph.customer_name , ph.invoice_date ;


		-- ***************************************************************************************************** -- 

	-- Q.8)	If data on promotional campaigns (discounts, events, email marketing) is available, how could you measure their impact
    --      on customer acquisition, retention, and overall sales?


select count(*) from track ;   --  total available tracks according to our data

select distinct t.name 
from track t
where t.track_id not in ( select il.track_id
						  from invoice_line il
                          left join invoice i on i.invoice_id = il.invoice_id
						  where i.invoice_date between '2020-07-01' and '2020-12-31') ;

-- Identifying songs that were not Purchased by any customer in previous 6 months.
-- So promotions campaigns can applied over them to promote their sales.

select c.email , concat(c.first_name, ' ', c.last_name) as Customer_Full_Name
from customer c
where c.customer_id not in (select distinct customer_id
							from invoice
                            where invoice_date between '2020-07-01' and '2020-12-31' ) ;
                            

-- Identifying those customer they have not made any purchase in previous 6 months.


		-- ***************************************************************************************************** -- 

	-- Q.9)	How would you approach this problem, if the objective and subjective questions weren't given?

-- If objective and subjective questions weren't given . then first I'll try to approach for finding
-- Duplicate and null value in each table , also year and country wise revenue

select * from album ;
select distinct * from album ; -- No any Duplicate 

select * from artist ;
select distinct * from artist ; -- No any Duplicate

select * from customer ;
select distinct * from customer ; -- No any Duplicate

select count(*) from customer 
where company is null ; -- 49 Null value

select count(*) from customer 
where state is null ;  -- 29 Null value

select count(*) from customer 
where fax is null ;  -- 47 Null value

select * from employee ;     -- employee_id 1 report_to is null
select distinct * from employee ;    -- No any Duplicate

select * from genre ;
select distinct * from genre ;  -- No any Duplicate

select * from invoice ;
select distinct * from invoice ; -- No any Duplicate

select * from invoice_line ;
select distinct * from invoice_line ; -- No any Duplicate

select * from media_type ;
select distinct * from media_type ; -- No any Duplicate

select * from playlist ;
select distinct * from playlist ; -- No any Duplicate

select * from playlist_track ;
select distinct * from playlist_track ; -- No any Duplicate

select * from track ;
select distinct * from track ;  -- No any Duplicate

 
select sum(total) as Yearly_Revenue , extract(year from invoice_date) as Year
from invoice
group by 2;

/*   Yearly revenue
1201.86 	2017
1147.41	    2018
1221.66 	2019
1138.50 	2020
*/

select billing_country , sum(total) as Total_Revenue
from invoice
group by billing_country
order by Total_Revenue desc ;


select customer_id , sum(total) as Lifetime_Purchase
from invoice
group by customer_id
order by  sum(total) desc ;


		-- ***************************************************************************************************** -- 

	-- Q.10)	How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year of each album?

alter table album
add column ReleaseYear int;
select * 
from album;

		-- ***************************************************************************************************** -- 

	-- Q.11)	Chinook is interested in understanding the purchasing behavior of customers based on their geographical location. 
    --         They want to know the average total amount spent by customers from each country, along with the number of customers
    --         and the average number of tracks purchased per customer. Write an SQL query to provide this information.


with average_spent as( select round(avg(total),2) as avg_total_amount_spent,
						count(distinct customer_id) as num_of_customer , billing_country
						from invoice i
						left join invoice_line il on il.invoice_id = i.invoice_id
						group by billing_country ),
Purchase_qty as (select i.customer_id, sum(quantity) as quantity_purchased 
				 from invoice i
				 left join invoice_line il on il.invoice_id = i.invoice_id
				 group by i.customer_id ),
average_by_country as ( select billing_country, round(avg(quantity_purchased),2) as avg_tracks_per_country
						from invoice i
						left join Purchase_qty pq on pq.customer_id = i.customer_id
						group by billing_country )
select * from average_spent
		 left join average_by_country ac on ac.billing_country = average_spent.billing_country ;





		-- ***************************************************************************************************** --         