/*
SQL porfolio project
https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india

questions :
1- query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
2- query to print highest spend month and amount spent in that month for each card type
3- query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
4- query to find city which had lowest percentage spend for gold card type
5- query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
6- query to find percentage contribution of spends by females for each expense type
7- which card and expense type combination saw highest month over month growth in Jan-2014
8- during weekends which city has highest total spend to total no of transcations ratio 
9- which city took least number of days to reach its 500th transaction after the first transaction in that city

*/

select * from
credit_card_transactions

--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with infoCte as
(select city,sum(amount) as totalSpend
from credit_card_transactions
group by city)
select top 5 *,round(totalSpend*100/(select sum(totalSpend) from infoCte)) as contribution_percent
from infoCte
order by totalSpend desc

--2- write a query to print highest-spend month and amount spent in that month for each card type

select * from
credit_card_transactions

with infoCte as
(select 
card_type,
datepart(year,transaction_date) as yearPart,
datepart(MONTH,transaction_date) as monthPart,
sum(amount) as totalAmount
from credit_card_transactions
group by card_type,datepart(year,transaction_date),
datepart(MONTH,transaction_date)),
report as
(select card_type,yearPart,monthPart,totalAmount,sum(totalAmount)over(partition by yearPart,monthPart) as monthlySum
from infoCte),
finalReport as
(select *,max(monthlySum)over(partition by yearPart order by card_type) as maxByYear
from report)
select card_type,yearPart,monthPart as highest_spend_month,totalAmount from
finalReport
where monthlySum=maxByYear




--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

select * from
credit_card_transactions

with infoCte as
(select *,sum(amount)over(partition by card_type order by transaction_date,transaction_id) as yearlySum
from credit_card_transactions),
finalReport as
(select *,rank()over(partition by card_type order by yearlySum) as rankedSum
from infoCte
where yearlySum>=1000000)
select * from
finalReport
where rankedSum=1



--4- write a query to find city which had lowest percentage spend for gold card type


select * from
credit_card_transactions

with infoCte as
(select transaction_id,city,card_type,sum(amount)over(partition by city order by card_type,transaction_id) as cityWiseCardSum,
(select sum(amount) from credit_card_transactions where card_type='Gold') as divider
from credit_card_transactions
where card_type='Gold'),
reportCte as
(select *,rank()over(partition by city order by cityWiseCardSum desc) as ranked
from infoCte),
finalReport as
(select *,round((cityWiseCardSum/divider)*100000,2) as parameter
from reportCte
where ranked=1)
select city,card_type,parameter  from finalReport
where parameter<=0.0



  
--city,card_type,parameter 
--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
select * from
credit_card_transactions


with infoCte as
(select city,exp_type,amount,sum(amount)over(partition by city,exp_type order by transaction_id) as sumByCityExp
from 
credit_card_transactions),
report as
(select *,rank()over(partition by city order by sumByCityExp desc) as rn_desc,
rank()over(partition by city order by sumByCityExp asc) as rn_asc
from infoCte)
select city,max(case when rn_desc=1 then exp_type end) as highest_expense_type ,
min(case when rn_asc=1 then exp_type end) as lowest_expense_type
from report
group by city


  
--6- write a query to find percentage contribution of spends by females for each expense type
select * from
credit_card_transactions


select exp_type,round((sum(case when gender='F' then amount end)*100/sum(amount)),2) as percentContriFemale
from credit_card_transactions
group by exp_type
order by percentContriFemale desc

  

--7- which card and expense type combination saw highest month over month growth in Jan-2014
select * from
credit_card_transactions

with infoCte as
(select format(transaction_date,'yyyy-MM') yearMonth,card_type,exp_type,sum(amount) monthlySum
from
credit_card_transactions
group by format(transaction_date,'yyyy-MM'),card_type,exp_type),
report as
(select *,lag(monthlySum,1)over(order by card_type,exp_type,yearMonth) as prevMonth
from infoCte),
finalReport as
(select *,(monthlySum-prevMonth) as monthOverMon_Growth
from report)
select top 1 * from finalReport
where yearMonth='2014-01' and prevMonth is not NULL
order by monthOverMon_Growth desc


  
--8-during weekends which city has highest total spend to total no of transcations ratio 
select * from
credit_card_transactions

select top 1 city,sum(amount)/count(transaction_id) as transRatio
from credit_card_transactions
where datepart(weekday,transaction_date) in (1,7)
group by city
order by transRatio desc



  
--9- which city took least number of days to reach its 500th transaction after the first transaction in that city
select * from
credit_card_transactions a


with infoCte as
(select *,
rank()over(partition by city order by transaction_date,transaction_id) as rankedTransAsc
from
credit_card_transactions)
select city,
datediff(day,min(case when rankedTransAsc=1 then transaction_date end),max(case when rankedTransAsc=500 then transaction_date end)) as daysTaken
from infoCte
group by city
having count(transaction_date)>=500
order by daysTaken






