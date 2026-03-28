# IPL 2026 Seed Data — Correct Squads & Schedule

# Skip if already seeded (prevents duplicates on each deploy restart)
if IplTeam.count > 0
  puts "Database already seeded (#{IplTeam.count} teams, #{IplPlayer.count} players). Skipping."
  return
end

puts "Seeding IPL 2026 data..."

# === IPL Teams ===
teams_data = [
  { name: "Mumbai Indians", short_name: "MI" },
  { name: "Chennai Super Kings", short_name: "CSK" },
  { name: "Royal Challengers Bengaluru", short_name: "RCB" },
  { name: "Kolkata Knight Riders", short_name: "KKR" },
  { name: "Delhi Capitals", short_name: "DC" },
  { name: "Rajasthan Royals", short_name: "RR" },
  { name: "Sunrisers Hyderabad", short_name: "SRH" },
  { name: "Punjab Kings", short_name: "PBKS" },
  { name: "Gujarat Titans", short_name: "GT" },
  { name: "Lucknow Super Giants", short_name: "LSG" }
]

teams = {}
teams_data.each do |data|
  team = IplTeam.find_or_create_by!(short_name: data[:short_name]) do |t|
    t.name = data[:name]
  end
  teams[data[:short_name]] = team
  puts "  Team: #{team.name}"
end

# === IPL 2026 Actual Squads ===
players_data = {
  "MI" => [
    { name: "Hardik Pandya", role: "all_rounder" },       # Captain
    { name: "Rohit Sharma", role: "batsman" },
    { name: "Suryakumar Yadav", role: "batsman" },
    { name: "Tilak Varma", role: "batsman" },
    { name: "Naman Dhir", role: "batsman" },
    { name: "Ryan Rickelton", role: "batsman" },
    { name: "Danish Malewar", role: "batsman" },
    { name: "Robin Minz", role: "wicket_keeper" },
    { name: "Quinton de Kock", role: "wicket_keeper" },
    { name: "Jasprit Bumrah", role: "bowler" },
    { name: "Trent Boult", role: "bowler" },
    { name: "Deepak Chahar", role: "bowler" },
    { name: "Allah Ghazanfar", role: "bowler" },
    { name: "Ashwani Kumar", role: "bowler" },
    { name: "Mayank Markande", role: "bowler" },
    { name: "Will Jacks", role: "all_rounder" },
    { name: "Mitchell Santner", role: "all_rounder" },
    { name: "Corbin Bosch", role: "all_rounder" },
    { name: "Raj Angad Bawa", role: "all_rounder" },
    { name: "Sherfane Rutherford", role: "all_rounder" },
    { name: "Shardul Thakur", role: "all_rounder" },
    { name: "Raghu Sharma", role: "bowler" },
    { name: "Atharva Ankolekar", role: "all_rounder" },
    { name: "Mohammad Izhar", role: "bowler" },
    { name: "Mayank Rawat", role: "batsman" },
  ],
  "CSK" => [
    { name: "Ruturaj Gaikwad", role: "batsman" },         # Captain
    { name: "MS Dhoni", role: "wicket_keeper" },
    { name: "Sanju Samson", role: "wicket_keeper" },
    { name: "Dewald Brevis", role: "batsman" },
    { name: "Ayush Mhatre", role: "batsman" },
    { name: "Sarfaraz Khan", role: "batsman" },
    { name: "Urvil Patel", role: "wicket_keeper" },
    { name: "Kartik Sharma", role: "wicket_keeper" },
    { name: "Rahul Tripathi", role: "batsman" },
    { name: "Shivam Dube", role: "all_rounder" },
    { name: "Aman Khan", role: "all_rounder" },
    { name: "Jamie Overton", role: "all_rounder" },
    { name: "Matthew Short", role: "all_rounder" },
    { name: "Khaleel Ahmed", role: "bowler" },
    { name: "Noor Ahmad", role: "bowler" },
    { name: "Nathan Ellis", role: "bowler" },
    { name: "Mukesh Choudhary", role: "bowler" },
    { name: "Shreyas Gopal", role: "bowler" },
    { name: "Rahul Chahar", role: "bowler" },
    { name: "Akeal Hosein", role: "all_rounder" },
    { name: "Gurjapneet Singh", role: "bowler" },
    { name: "Matt Henry", role: "bowler" },
    { name: "Anshul Kamboj", role: "all_rounder" },
    { name: "Ramakrishna Ghosh", role: "batsman" },
    { name: "Prashant Veer", role: "bowler" },
    { name: "Zak Foulkes", role: "bowler" },
  ],
  "RCB" => [
    { name: "Rajat Patidar", role: "batsman" },           # Captain
    { name: "Virat Kohli", role: "batsman" },
    { name: "Devdutt Padikkal", role: "batsman" },
    { name: "Phil Salt", role: "wicket_keeper" },
    { name: "Jitesh Sharma", role: "wicket_keeper" },
    { name: "Tim David", role: "batsman" },
    { name: "Jacob Bethell", role: "all_rounder" },
    { name: "Krunal Pandya", role: "all_rounder" },
    { name: "Swapnil Singh", role: "all_rounder" },
    { name: "Romario Shepherd", role: "all_rounder" },
    { name: "Liam Livingstone", role: "all_rounder" },
    { name: "Josh Hazlewood", role: "bowler" },
    { name: "Bhuvneshwar Kumar", role: "bowler" },
    { name: "Yash Dayal", role: "bowler" },
    { name: "Nuwan Thushara", role: "bowler" },
    { name: "Rasikh Salam", role: "bowler" },
    { name: "Suyash Sharma", role: "bowler" },
    { name: "Abhinandan Singh", role: "bowler" },
  ],
  "KKR" => [
    { name: "Shreyas Iyer", role: "batsman" },
    { name: "Nehal Wadhera", role: "batsman" },
    { name: "Harnoor Pannu", role: "batsman" },
    { name: "Musheer Khan", role: "batsman" },
    { name: "Priyansh Arya", role: "batsman" },
    { name: "Suryansh Shedge", role: "all_rounder" },
    { name: "Vishnu Vinod", role: "wicket_keeper" },
    { name: "Prabhsimran Singh", role: "wicket_keeper" },
    { name: "Shashank Singh", role: "all_rounder" },
    { name: "Marcus Stoinis", role: "all_rounder" },
    { name: "Azmatullah Omarzai", role: "all_rounder" },
    { name: "Harpreet Brar", role: "all_rounder" },
    { name: "Cooper Connolly", role: "all_rounder" },
    { name: "Mitch Owen", role: "all_rounder" },
    { name: "Marco Jansen", role: "all_rounder" },
    { name: "Cameron Green", role: "all_rounder" },
    { name: "Arshdeep Singh", role: "bowler" },
    { name: "Yuzvendra Chahal", role: "bowler" },
    { name: "Matheesha Pathirana", role: "bowler" },
    { name: "Lockie Ferguson", role: "bowler" },
    { name: "Xavier Bartlett", role: "bowler" },
    { name: "Vyshak Vijaykumar", role: "bowler" },
    { name: "Yash Thakur", role: "bowler" },
    { name: "Ben Dwarshuis", role: "bowler" },
    { name: "Pravin Dubey", role: "bowler" },
    { name: "Blessing Muzarabani", role: "bowler" },
    { name: "Pyla Avinash", role: "batsman" },
  ],
  "DC" => [
    { name: "Axar Patel", role: "all_rounder" },          # Captain
    { name: "KL Rahul", role: "wicket_keeper" },
    { name: "Abishek Porel", role: "wicket_keeper" },
    { name: "Ben Duckett", role: "batsman" },
    { name: "Karun Nair", role: "batsman" },
    { name: "David Miller", role: "batsman" },
    { name: "Pathum Nissanka", role: "batsman" },
    { name: "Prithvi Shaw", role: "batsman" },
    { name: "Sameer Rizvi", role: "batsman" },
    { name: "Ashutosh Sharma", role: "all_rounder" },
    { name: "Tristan Stubbs", role: "batsman" },
    { name: "Jake Fraser-McGurk", role: "batsman" },
    { name: "Faf du Plessis", role: "batsman" },
    { name: "Vipraj Nigam", role: "all_rounder" },
    { name: "Madhav Tiwari", role: "all_rounder" },
    { name: "Nitish Rana", role: "all_rounder" },
    { name: "Mitchell Starc", role: "bowler" },
    { name: "T Natarajan", role: "bowler" },
    { name: "Mukesh Kumar", role: "bowler" },
    { name: "Kuldeep Yadav", role: "bowler" },
    { name: "Dushmantha Chameera", role: "bowler" },
    { name: "Lungisani Ngidi", role: "bowler" },
    { name: "Kyle Jamieson", role: "bowler" },
    { name: "Mohit Sharma", role: "bowler" },
    { name: "Darshan Nalkande", role: "bowler" },
  ],
  "RR" => [
    { name: "Yashasvi Jaiswal", role: "batsman" },
    { name: "Shimron Hetmyer", role: "batsman" },
    { name: "Shubham Dubey", role: "batsman" },
    { name: "Vaibhav Suryavanshi", role: "batsman" },
    { name: "Lhuan-dre Pretorius", role: "all_rounder" },
    { name: "Dhruv Jurel", role: "wicket_keeper" },
    { name: "Donovan Ferreira", role: "all_rounder" },
    { name: "Ravindra Jadeja", role: "all_rounder" },
    { name: "Sam Curran", role: "all_rounder" },
    { name: "Riyan Parag", role: "all_rounder" },
    { name: "Yudhvir Singh", role: "all_rounder" },
    { name: "Aman Rao", role: "batsman" },
    { name: "Ravi Singh", role: "batsman" },
    { name: "Ravi Bishnoi", role: "bowler" },
    { name: "Jofra Archer", role: "bowler" },
    { name: "Sandeep Sharma", role: "bowler" },
    { name: "Tushar Deshpande", role: "bowler" },
    { name: "Nandre Burger", role: "bowler" },
    { name: "Sushant Mishra", role: "bowler" },
    { name: "Adam Milne", role: "bowler" },
    { name: "Kuldeep Sen", role: "bowler" },
    { name: "Kwena Maphaka", role: "bowler" },
    { name: "Yash Raj Punja", role: "bowler" },
    { name: "Vignesh Puthur", role: "bowler" },
    { name: "Brijesh Sharma", role: "wicket_keeper" },
  ],
  "SRH" => [
    { name: "Pat Cummins", role: "all_rounder" },         # Captain
    { name: "Travis Head", role: "batsman" },
    { name: "Abhishek Sharma", role: "all_rounder" },
    { name: "Ishan Kishan", role: "wicket_keeper" },
    { name: "Heinrich Klaasen", role: "wicket_keeper" },
    { name: "Aniket Verma", role: "batsman" },
    { name: "Sachin Baby", role: "batsman" },
    { name: "Atharva Taide", role: "batsman" },
    { name: "Jack Edwards", role: "all_rounder" },
    { name: "Salil Arora", role: "batsman" },
    { name: "Nitish Kumar Reddy", role: "all_rounder" },
    { name: "Liam Livingstone", role: "all_rounder" },
    { name: "Kamindu Mendis", role: "all_rounder" },
    { name: "Brydon Carse", role: "all_rounder" },
    { name: "Harsh Dubey", role: "all_rounder" },
    { name: "Harshal Patel", role: "bowler" },
    { name: "Jaydev Unadkat", role: "bowler" },
    { name: "Zeeshan Ansari", role: "bowler" },
    { name: "Eshan Malinga", role: "bowler" },
    { name: "Sakib Hussain", role: "bowler" },
    { name: "Shivam Mavi", role: "bowler" },
    { name: "Amit Kumar", role: "bowler" },
    { name: "Onkar Tarmale", role: "bowler" },
    { name: "Shivang Kumar", role: "all_rounder" },
    { name: "Praful Hinge", role: "all_rounder" },
    { name: "Krains Fuletra", role: "all_rounder" },
    { name: "R Smaran", role: "batsman" },
  ],
  "PBKS" => [
    { name: "Shreyas Iyer", role: "batsman" },            # Note: search shows PBKS retained Shreyas
    { name: "Shashank Singh", role: "all_rounder" },
    { name: "Nehal Wadhera", role: "batsman" },
    { name: "Prabhsimran Singh", role: "wicket_keeper" },
    { name: "Priyansh Arya", role: "batsman" },
    { name: "Harnoor Pannu", role: "batsman" },
    { name: "Musheer Khan", role: "batsman" },
    { name: "Vishnu Vinod", role: "wicket_keeper" },
    { name: "Marcus Stoinis", role: "all_rounder" },
    { name: "Azmatullah Omarzai", role: "all_rounder" },
    { name: "Harpreet Brar", role: "all_rounder" },
    { name: "Marco Jansen", role: "all_rounder" },
    { name: "Suryansh Shedge", role: "all_rounder" },
    { name: "Mitch Owen", role: "all_rounder" },
    { name: "Cooper Connolly", role: "all_rounder" },
    { name: "Arshdeep Singh", role: "bowler" },
    { name: "Yuzvendra Chahal", role: "bowler" },
    { name: "Lockie Ferguson", role: "bowler" },
    { name: "Xavier Bartlett", role: "bowler" },
    { name: "Vyshak Vijaykumar", role: "bowler" },
    { name: "Yash Thakur", role: "bowler" },
    { name: "Pyla Avinash", role: "batsman" },
  ],
  "GT" => [
    { name: "Shubman Gill", role: "batsman" },            # Captain
    { name: "Sai Sudharsan", role: "batsman" },
    { name: "Shahrukh Khan", role: "batsman" },
    { name: "Jos Buttler", role: "wicket_keeper" },
    { name: "Tom Banton", role: "wicket_keeper" },
    { name: "Glenn Phillips", role: "wicket_keeper" },
    { name: "Anuj Rawat", role: "wicket_keeper" },
    { name: "Kumar Kushagra", role: "wicket_keeper" },
    { name: "Rashid Khan", role: "all_rounder" },
    { name: "Washington Sundar", role: "all_rounder" },
    { name: "Rahul Tewatia", role: "all_rounder" },
    { name: "Jason Holder", role: "all_rounder" },
    { name: "Nishant Sindhu", role: "all_rounder" },
    { name: "Jayant Yadav", role: "all_rounder" },
    { name: "Manav Suthar", role: "bowler" },
    { name: "Kagiso Rabada", role: "bowler" },
    { name: "Mohammed Siraj", role: "bowler" },
    { name: "Prasidh Krishna", role: "bowler" },
    { name: "Ishant Sharma", role: "bowler" },
    { name: "Luke Wood", role: "bowler" },
    { name: "Sai Kishore", role: "bowler" },
    { name: "Gurnoor Brar", role: "bowler" },
    { name: "Arshad Khan", role: "bowler" },
    { name: "Ashok Sharma", role: "bowler" },
    { name: "Prithvi Raj Yarra", role: "batsman" },
  ],
  "LSG" => [
    { name: "Rishabh Pant", role: "wicket_keeper" },      # Captain
    { name: "Nicholas Pooran", role: "wicket_keeper" },
    { name: "Josh Inglis", role: "wicket_keeper" },
    { name: "Aiden Markram", role: "batsman" },
    { name: "Ayush Badoni", role: "batsman" },
    { name: "Himmat Singh", role: "batsman" },
    { name: "Matthew Breetzke", role: "batsman" },
    { name: "Akshat Raghuwanshi", role: "batsman" },
    { name: "Mitchell Marsh", role: "all_rounder" },
    { name: "Arshin Kulkarni", role: "all_rounder" },
    { name: "Shahbaz Ahmed", role: "all_rounder" },
    { name: "Abdul Samad", role: "all_rounder" },
    { name: "Wanindu Hasaranga", role: "all_rounder" },
    { name: "Prince Yadav", role: "all_rounder" },
    { name: "Mohammad Shami", role: "bowler" },
    { name: "Avesh Khan", role: "bowler" },
    { name: "Mayank Yadav", role: "bowler" },
    { name: "Mohsin Khan", role: "bowler" },
    { name: "Anrich Nortje", role: "bowler" },
    { name: "Arjun Tendulkar", role: "bowler" },
    { name: "M Siddharth", role: "bowler" },
    { name: "Digvesh Singh", role: "bowler" },
    { name: "Akash Singh", role: "bowler" },
    { name: "Ravi Bishnoi", role: "bowler" },
    { name: "Shamar Joseph", role: "bowler" },
  ]
}

# Clear existing players and re-seed
IplPlayer.destroy_all
players_data.each do |short_name, players|
  team = teams[short_name]
  players.each do |pdata|
    IplPlayer.create!(name: pdata[:name], ipl_team: team, role: pdata[:role])
  end
  puts "  #{short_name}: #{players.size} players seeded"
end

# === IPL 2026 Official Schedule (First 20 matches - BCCI announced) ===
# Full schedule not yet released due to state elections
Match.destroy_all
matches_data = [
  { match_number: 1,  team1: "RCB", team2: "SRH",  date: "2026-03-28 19:30", venue: "M Chinnaswamy Stadium, Bengaluru" },
  { match_number: 2,  team1: "MI",  team2: "KKR",  date: "2026-03-29 19:30", venue: "Wankhede Stadium, Mumbai" },
  { match_number: 3,  team1: "RR",  team2: "CSK",  date: "2026-03-30 19:30", venue: "ACA Stadium, Guwahati" },
  { match_number: 4,  team1: "PBKS",team2: "GT",   date: "2026-03-31 19:30", venue: "PCA Stadium, New Chandigarh" },
  { match_number: 5,  team1: "LSG", team2: "DC",   date: "2026-04-01 19:30", venue: "Ekana Cricket Stadium, Lucknow" },
  { match_number: 6,  team1: "KKR", team2: "SRH",  date: "2026-04-02 19:30", venue: "Eden Gardens, Kolkata" },
  { match_number: 7,  team1: "CSK", team2: "PBKS", date: "2026-04-03 19:30", venue: "MA Chidambaram Stadium, Chennai" },
  { match_number: 8,  team1: "DC",  team2: "MI",   date: "2026-04-04 15:30", venue: "Arun Jaitley Stadium, Delhi" },
  { match_number: 9,  team1: "GT",  team2: "RR",   date: "2026-04-04 19:30", venue: "Narendra Modi Stadium, Ahmedabad" },
  { match_number: 10, team1: "SRH", team2: "LSG",  date: "2026-04-05 15:30", venue: "Rajiv Gandhi Intl Stadium, Hyderabad" },
  { match_number: 11, team1: "RCB", team2: "CSK",  date: "2026-04-05 19:30", venue: "M Chinnaswamy Stadium, Bengaluru" },
  { match_number: 12, team1: "KKR", team2: "PBKS", date: "2026-04-06 19:30", venue: "Eden Gardens, Kolkata" },
  { match_number: 13, team1: "RR",  team2: "MI",   date: "2026-04-07 19:30", venue: "ACA Stadium, Guwahati" },
  { match_number: 14, team1: "DC",  team2: "GT",   date: "2026-04-08 19:30", venue: "Arun Jaitley Stadium, Delhi" },
  { match_number: 15, team1: "KKR", team2: "LSG",  date: "2026-04-09 19:30", venue: "Eden Gardens, Kolkata" },
  { match_number: 16, team1: "MI",  team2: "SRH",  date: "2026-04-10 19:30", venue: "Wankhede Stadium, Mumbai" },
  { match_number: 17, team1: "PBKS",team2: "RCB",  date: "2026-04-11 15:30", venue: "PCA Stadium, New Chandigarh" },
  { match_number: 18, team1: "CSK", team2: "DC",   date: "2026-04-11 19:30", venue: "MA Chidambaram Stadium, Chennai" },
  { match_number: 19, team1: "GT",  team2: "LSG",  date: "2026-04-12 15:30", venue: "Narendra Modi Stadium, Ahmedabad" },
  { match_number: 20, team1: "RR",  team2: "KKR",  date: "2026-04-12 19:30", venue: "Sawai Mansingh Stadium, Jaipur" },
]

matches_data.each do |mdata|
  Match.create!(
    match_number: mdata[:match_number],
    team1: teams[mdata[:team1]],
    team2: teams[mdata[:team2]],
    match_date: DateTime.parse(mdata[:date] + " +05:30"),
    venue: mdata[:venue],
    status: "upcoming"
  )
end

puts "  #{matches_data.size} matches seeded (official BCCI schedule, remaining TBD)"

# === Create default users ===
User.destroy_all
{ "Naveen" => "naveen123", "Nithish" => "nithish123", "Rahul" => "rahul123" }.each do |name, pwd|
  User.create!(name: name, password: pwd)
end
puts "  3 default users seeded (with passwords)"

puts "Done! Seeded #{IplTeam.count} teams, #{IplPlayer.count} players, #{Match.count} matches, #{User.count} users."
