/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT * 
FROM Facilities 
WHERE membercost > 0;

/* Q2: How many facilities do not charge a fee to members? */
4

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT * 
FROM Facilities 
WHERE membercost < 0.2*monthlymaintenance;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT * 
FROM Facilities 
WHERE facid 
IN(1,5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
CASE WHEN monthlymaintenance >100
THEN 'expensive'
WHEN monthlymaintenance <=100
THEN 'cheap'
END AS expensiveorcheap
FROM Facilities

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE joindate
IN (
SELECT MAX(joindate)
FROM Members)

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT F.name AS courtname, CONCAT( M.firstname, ' ', M.surname ) AS membername
FROM Members AS M
INNER JOIN Bookings AS B ON B.memid = M.memid
INNER JOIN Facilities AS F ON B.facid = F.facid
WHERE (
B.facid =0
OR B.facid =1)
AND (
F.facid =0
OR F.facid =1)
ORDER BY membername


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT F.name AS facilityname, CONCAT( M.firstname, ' ', M.surname ) AS membername,
   CASE WHEN F.membercost >30 AND M.memid <>0
	THEN F.membercost * B.slots
	WHEN F.guestcost >30 AND M.memid =0
	THEN F.guestcost * B.slots
	END AS cost
FROM Members AS M
LEFT JOIN Bookings AS B ON B.memid = M.memid
LEFT JOIN Facilities AS F ON B.facid = F.facid
WHERE DATE( B.starttime ) = '2012-09-14'
ORDER BY cost DESC

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT  cst.facilityname, CONCAT( cst.firstname, ' ', cst.surname ) AS membername, cst.cost
FROM (
   SELECT F.name AS facilityname, M.firstname, M.surname,
    CASE WHEN F.membercost >30 AND M.memid <>0
	THEN F.membercost * B.slots
	WHEN F.guestcost >30 AND M.memid =0
	THEN F.guestcost * B.slots
	END AS cost  
   FROM Members AS M
   LEFT JOIN Bookings AS B ON B.memid = M.memid
   LEFT JOIN Facilities AS F ON B.facid = F.facid
   WHERE DATE( B.starttime ) = '2012-09-14') AS cst
WHERE cost IS NOT NULL
ORDER BY cost DESC;


/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT rev.facilityname, SUM( rev.revenue ) AS total_revenue
FROM (
	SELECT F.name AS facilityname,
	CASE WHEN B.memid <>0
	THEN F.membercost * B.slots
	WHEN B.memid =0
	THEN F.guestcost * B.slots
	END AS revenue
	FROM Bookings AS B
	LEFT JOIN Members AS M ON B.memid = M.memid
	LEFT JOIN Facilities AS F ON B.facid = F.facid) AS rev
GROUP BY rev.facilityname
HAVING total_revenue <1000
ORDER BY total_revenue DESC


/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT R.firstname AS memberfirstname, R.surname AS membersurname, M.firstname AS recommenderfirstname, M.surname AS recommenderlastname
FROM Members AS M
INNER JOIN Members AS R ON M.memid = R.recommendedby
WHERE M.memid <>0
ORDER BY R.surname, R.firstname

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT usi.facilityname, SUM( usi.usa ) AS member_usage_hours, usi.firstname, usi.surname, usi.memid
FROM (
	SELECT F.name AS facilityname, M.firstname, M.surname, B.memid,
	CASE WHEN B.memid <>0
	THEN 30 * B.slots /60
	END AS usa
	FROM Bookings AS B
	LEFT JOIN Members AS M ON B.memid = M.memid
	LEFT JOIN Facilities AS F ON B.facid = F.facid) AS usi
GROUP BY usi.memid
ORDER BY member_usage_hours DESC
LIMIT 29

/* Q13: Find the facilities usage by month, but not guests */

SELECT usi.facilityname, SUM( usi.usa ) AS member_usage_per_month
FROM (
SELECT F.name AS facilityname,
	CASE WHEN B.memid <>0
	THEN ( 30 * B.slots /60 ) / ( 24 *30 )
	END AS usa
FROM Bookings AS B
LEFT JOIN Members AS M ON B.memid = M.memid
LEFT JOIN Facilities AS F ON B.facid = F.facid) AS usi
GROUP BY usi.facilityname
ORDER BY member_usage_per_month DESC
