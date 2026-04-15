\# Dashboard Analysis — Zomato Bangalore



Three pages.
Every page is actually answering one question, that would answer any person who want to know about Bangalore restaurant market for the first time.



\## Page 1 — Where does Bangalore eat?



* This is the landscape page. The numbers on the top gives you perspective of how city's restaurant data looks like:
1. &#x09;12,494 restaurants
2. &#x09;3.63 average rating
3. &#x09;₹488 cost for two people
4. &#x09;52% restaurants have online business
* The treemap indicates which type of cuisine is dominating. Unsurprisingly North Indian and South Indian are with top spots.
* To be honest, the most shocking discovery was that Fast Food and Bakery cuisine have more restaurants than the Chinese. 
* The bar chart on right side shows that Pubs and Nightlife places get rated around 0.4 stars higher than Delivery. Makes sense if you think about it — people rate an experience higher than just a transaction.
* Looking at the right side, bar chart indicates, shows that 0.4 rating difference between the Pubs and Nightlife venues than the delivering restaurants. It makes sense that people rate higher for the experience rather than just simple transaction.



\## Page 2 — Where is the money?

* Three useful insights here, each one as a separate visual.
* The market-gaps table is the main thing. Marathahalli location has only three European restaurants and they are averaging 4.5 stars with 5,650 votes per restaurant, the strongest under-supply signal in the whole dataset. Indiranagar (European) and Koramangala 4th Block (American) are the next best options. If any restaurant investor were looking to invest, this is the data I would strongly recommend.
* The online-order chart controls for price tier, which is important. Cheap restaurants mostly have online ordering, so without controlling for this you would wrongly conclude that online ordering is causing higher ratings. What the chart is actually showing — online ordering adds about +0.14 stars in Mid and Luxury tiers but only +0.04 in Premium. And luxury restaurants mostly don't even offer it.
* The value-leaders bar shows which localities are giving most rating per rupee. City Market, Varthur Main Road, and Basavanagudi are on top — old Bangalore areas with cheap, decent food.



\## Page 3 — Are Zomato stars telling the truth?

* This page is comparing star ratings against review-text sentiment (used VADER scores on the actual reviews\_list column). The scatter plot shows a clear positive diagonal — stars and sentiment are mostly agreeing with each other. The interesting cases are the outliers.
* "High stars, cold reviews" lists restaurants where the star rating is not matching with the text. Underpass Pub at 4.0 stars but sentiment is only +0.28 across 150 written reviews — that kind of gap is worth asking some questions about.
* "Low stars, warm reviews" is the opposite. Places rated below 3.2 but people are writing very good reviews about them. Either they got review-bombed early on, or Zomato's rating algorithm is weighing something other than the actual written text.
* The point of this page is not to accuse anyone of rating inflation. It is just to show that when two signals are not agreeing, the disagreement itself is a signal worth looking at.

