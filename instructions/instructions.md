# iOS App Requirements Document  


---

## 1. App Overview  
This app is for drivers in Singapore. It helps them save money on fuel, parking, and tolls. The user picks a start point and an end point. The app then works out the full trip cost using fuel cost, parking cost, and toll cost. It also finds the cheapest route. The app shows live navigation and helps the user drive safely with things like red-light camera alerts and traffic light countdowns.

---

## 2. Main Goals  
1. Help users find the most money-saving route while still considering travel time.  
2. Track how much users spend on fuel, parking, and tolls each day, month, and year.  
3. Give live navigation inside the app.  
4. Show red-light cameras and traffic light countdowns to help users drive calmly.

---

## 3. User Stories  

- **US-001** — As a user, I want to calculate the most affordable trip plan so that I can save the most money.  
- **US-002** — As a user, I want to know my daily driving costs so that I can make smarter money choices.  
- **US-003** — As a user, I want a navigation map that shows traffic light countdowns and red-light cameras so that I can drive more smoothly.  
- **US-004** — As a user, I want to track how much I spend on petrol, parking, and tolls for the day, month, and year so I can understand my habits.

---

## 4. Features  

- **F-001: Live Navigation**  
  - Shows a map with directions while driving.  
  - Appears when the user starts a trip.  
  - If something breaks, show: “Navigation not available now.”

- **F-002: Trip Cost and Savings Calculator**  
  - Calculates fuel, parking, and toll costs.  
  - Also compares the “normal route” vs “recommended route” to show savings.  
  - Appears after the user enters their start and end point.  
  - If something breaks, show: “We could not calculate your trip cost.”

- **F-003: Save Car Details and Savings Info**  
  - Stores car type, fuel consumption, fuel price, and total savings.  
  - Used every time the app calculates costs.  
  - If missing, ask the user to fill it in.

- **F-004: AI Route Recommendations**  
  - Uses AI to choose the best route based on time and money.  
  - Learns from past trips and gives safety ideas for certain roads.  
  - If AI is down, show: “AI suggestions unavailable.”

- **F-005: Traffic Light Countdown**  
  - Shows how many seconds until the light changes.  
  - If no data is available, hide the countdown.

- **F-006: Red-Light Cameras and Road Block Alerts**  
  - Warns users about these dangers while driving.  
  - If data fails, hide alerts but keep navigation running.

- **F-007: Spending Memory System**  
  - Saves daily, monthly, and yearly costs.  
  - If it cannot load, show “No data found.”

---

## 5. Screens  

- **S-001: Home Screen**  
  - Buttons: “Plan Trip”, “Navigation”, “Spending”, “Settings”.  
  - First screen when the app opens.

- **S-002: Trip Planner Screen**  
  - User enters start and end point.  
  - Shows total cost, savings, and route choices.  
  - Comes from Home Screen.

- **S-003: Live Navigation Screen**  
  - Shows map, directions, traffic light countdown, camera alerts.  
  - Comes from Trip Planner.

- **S-004: Spending Screen**  
  - Shows daily, monthly, and yearly spending.  
  - Comes from Home Screen.

- **S-005: Settings Screen**  
  - User sets car info and fuel price.  
  - Comes from Home Screen.

---

## 6. Data  

- **D-001:** Fuel cost per day  
- **D-002:** Fuel cost per month  
- **D-003:** Fuel cost per year  
- **D-004:** Toll cost per day / month / year  
- **D-005:** Parking cost per day / month / year  
- **D-006:** Total savings per day / month / year  
- **D-007:** Car type, fuel use, fuel price  
- **D-008:** Trip history and recommended route savings  
- **D-009:** Traffic light, camera, and road block live data

---

## 7. Extra Details  

- Needs internet connection for maps and live data.  
- Stores user data safely on the device.  
- Needs location permission for navigation.  
- Needs network permission.  
- Works in dark mode.  
- Uses Google API and Google AI API.  
- Uses fun icons, simple layout, easy fonts.
- Set up github backup using githib CLI

---

---

