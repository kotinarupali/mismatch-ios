#!/usr/bin/env python3
"""Generate bundled word pack JSON files for Mismatch."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "mismatch" / "Resources" / "WordPacks"
SEED_PATH = Path(__file__).resolve().parent / "word_pack_data" / "general_seed.json"
DATA_DIR = Path(__file__).resolve().parent / "word_pack_data"


def unique_titles(titles: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for title in titles:
        cleaned = " ".join(title.split())
        key = cleaned.casefold()
        if not key or key in seen:
            continue
        seen.add(key)
        result.append(cleaned)
    return result


def load_title_file(name: str) -> list[str]:
    path = DATA_DIR / name
    if not path.exists():
        return []
    return [
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]


def load_similar_pairs_file(name: str, category: str) -> list[tuple[str, str, str]]:
    path = DATA_DIR / name
    if not path.exists():
        raise FileNotFoundError(f"Missing similar-pairs file: {path}")
    rows = json.loads(path.read_text(encoding="utf-8"))
    pairs: list[tuple[str, str, str]] = []
    for row in rows:
        insider = row["insider"].strip()
        mismatch = row["mismatch"].strip()
        pairs.append((insider, mismatch, category))
    return pairs


def merge_title_lists(*sources: list[str]) -> list[str]:
    merged: list[str] = []
    for source in sources:
        merged.extend(source)
    return unique_titles(merged)


def write_pack(pack_id: str, display_name: str, pairs: list[tuple[str, str, str]]) -> None:
    payload = {
        "id": pack_id,
        "displayName": display_name,
        "isBuiltIn": True,
        "pairs": [
            {
                "id": str(index),
                "insiderWord": insider,
                "mismatchWord": mismatch,
                "category": category,
            }
            for index, (insider, mismatch, category) in enumerate(pairs, start=1)
        ],
    }
    path = OUT_DIR / f"{pack_id}.json"
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {path.name}: {len(pairs)} pairs")


def dedupe_pairs(pairs: list[tuple[str, str, str]]) -> list[tuple[str, str, str]]:
    seen: set[tuple[str, str]] = set()
    result: list[tuple[str, str, str]] = []
    for insider, mismatch, category in pairs:
        key = (insider.casefold(), mismatch.casefold())
        reverse = (mismatch.casefold(), insider.casefold())
        if key in seen or reverse in seen or insider.casefold() == mismatch.casefold():
            continue
        seen.add(key)
        result.append((insider, mismatch, category))
    return result


def unique_word_pairs(
    pairs: list[tuple[str, str, str]],
    target: int | None = None,
) -> list[tuple[str, str, str]]:
    """Keep pairs where neither word appears anywhere else in the pack."""
    used_words: set[str] = set()
    seen_pairs: set[tuple[str, str]] = set()
    result: list[tuple[str, str, str]] = []

    for insider, mismatch, category in pairs:
        insider_key = insider.casefold()
        mismatch_key = mismatch.casefold()
        if insider_key == mismatch_key:
            continue
        if insider_key in used_words or mismatch_key in used_words:
            continue

        pair_key = (insider_key, mismatch_key)
        reverse_key = (mismatch_key, insider_key)
        if pair_key in seen_pairs or reverse_key in seen_pairs:
            continue

        seen_pairs.add(pair_key)
        used_words.add(insider_key)
        used_words.add(mismatch_key)
        result.append((insider, mismatch, category))
        if target is not None and len(result) >= target:
            break

    return result


def load_existing_general() -> list[tuple[str, str, str]]:
    path = SEED_PATH if SEED_PATH.exists() else OUT_DIR / "general.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    return [(p["insiderWord"], p["mismatchWord"], p["category"]) for p in data["pairs"]]


def general_extra_pairs() -> list[tuple[str, str, str]]:
    """Curated general pairs grouped by category."""
    raw: list[tuple[str, str, str]] = []

    def add(category: str, items: list[tuple[str, str]]) -> None:
        raw.extend((a, b, category) for a, b in items)

    add("Places", [
        ("Hotel", "Motel"), ("Theater", "Cinema"), ("Stadium", "Arena"), ("Temple", "Shrine"),
        ("Castle", "Palace"), ("Farm", "Ranch"), ("Village", "Town"), ("City", "Metropolis"),
        ("Harbor", "Port"), ("Bridge", "Overpass"), ("Tunnel", "Subway"), ("Park", "Garden"),
        ("Zoo", "Aquarium"), ("Casino", "Arcade"), ("Spa", "Salon"), ("Gym", "Fitness Center"),
        ("Office", "Studio"), ("Factory", "Warehouse"), ("School", "Academy"), ("Prison", "Jail"),
        ("Cemetery", "Graveyard"), ("Cathedral", "Chapel"), ("Mosque", "Synagogue"), ("Bakery", "Cafe"),
        ("Bar", "Pub"), ("Nightclub", "Lounge"), ("Mall", "Outlet"), ("Market", "Bazaar"),
        ("Supermarket", "Grocery"), ("Pharmacy", "Drugstore"), ("Bank", "Credit Union"),
        ("Post Office", "Courier"), ("Airport Terminal", "Bus Terminal"), ("Parking Garage", "Lot"),
        ("Apartment", "Condo"), ("Cottage", "Cabin"), ("Mansion", "Estate"), ("Hostel", "Inn"),
        ("Resort", "Retreat"), ("Campground", "Campsite"), ("Beach", "Shore"), ("Island", "Peninsula"),
        ("Desert", "Dunes"), ("Forest", "Woods"), ("Jungle", "Rainforest"), ("Mountain", "Hill"),
        ("Valley", "Canyon"), ("Lake", "Pond"), ("Ocean", "Sea"), ("Waterfall", "Rapids"),
        ("Observatory", "Planetarium"), ("Laboratory", "Workshop"), ("Library", "Archive"),
        ("Courthouse", "City Hall"), ("Embassy", "Consulate"), ("Border", "Checkpoint"),
        ("Highway", "Freeway"), ("Alley", "Lane"), ("Plaza", "Square"), ("Boardwalk", "Pier"),
        ("Marina", "Dock"), ("Greenhouse", "Nursery"), ("Barn", "Shed"), ("Lighthouse", "Beacon"),
        ("Observatory Deck", "Balcony"), ("Rooftop", "Terrace"), ("Basement", "Cellar"),
        ("Attic", "Loft"), ("Pantry", "Cupboard"), ("Closet", "Wardrobe"), ("Garage", "Carport"),
        ("Driveway", "Pathway"), ("Fence", "Gate"), ("Fountain", "Statue"), ("Monument", "Memorial"),
        ("Ruins", "Remains"), ("Fort", "Bunker"), ("Tower", "Spire"), ("Wall", "Barrier"),
        ("Gate", "Entrance"), ("Lobby", "Foyer"), ("Hallway", "Corridor"), ("Elevator", "Escalator"),
        ("Restroom", "Washroom"), ("Kitchen", "Pantry"), ("Dining Room", "Banquet Hall"),
        ("Bedroom", "Suite"), ("Nursery", "Playroom"), ("Garage Sale", "Flea Market"),
        ("Convention Center", "Expo Hall"), ("Auditorium", "Amphitheater"), ("Gallery", "Exhibit"),
        ("Bookstore", "Newsstand"), ("Florist", "Garden Center"), ("Hardware Store", "Tool Shop"),
        ("Pet Store", "Veterinary Clinic"), ("Daycare", "Preschool"), ("University", "College"),
        ("Dormitory", "Frat House"), ("Labor Camp", "Quarry"), ("Mine", "Quarry"),
        ("Refinery", "Plant"), ("Power Plant", "Substation"), ("Dam", "Reservoir"),
        ("Wind Farm", "Solar Farm"), ("Observatory Hill", "Lookout"), ("Trailhead", "Crossroads"),
    ])

    add("Food", [
        ("Pancake", "Waffle"), ("Burger", "Sandwich"), ("Hot Dog", "Sausage"), ("Steak", "Roast"),
        ("Salad", "Slaw"), ("Soup", "Stew"), ("Curry", "Stew"), ("Rice", "Quinoa"),
        ("Pasta", "Noodles"), ("Ravioli", "Dumpling"), ("Lasagna", "Casserole"), ("Pizza", "Flatbread"),
        ("Burrito", "Wrap"), ("Taco", "Quesadilla"), ("Nachos", "Chips"), ("Sushi", "Sashimi"),
        ("Ramen", "Pho"), ("Dumplings", "Potstickers"), ("Spring Roll", "Egg Roll"),
        ("Fried Rice", "Pilaf"), ("Omelette", "Frittata"), ("Scramble", "Hash"), ("Toast", "Bagel"),
        ("Croissant", "Danish"), ("Muffin", "Cupcake"), ("Cookie", "Biscuit"), ("Brownie", "Blondie"),
        ("Cake", "Torte"), ("Pie", "Tart"), ("Ice Cream", "Gelato"), ("Sorbet", "Sherbet"),
        ("Yogurt", "Kefir"), ("Milkshake", "Smoothie"), ("Coffee", "Espresso"), ("Tea", "Chai"),
        ("Hot Chocolate", "Cocoa"), ("Lemonade", "Iced Tea"), ("Soda", "Sparkling Water"),
        ("Wine", "Champagne"), ("Beer", "Cider"), ("Cocktail", "Mocktail"), ("Whiskey", "Bourbon"),
        ("Vodka", "Gin"), ("Rum", "Tequila"), ("Cheese", "Butter"), ("Cream", "Half-and-Half"),
        ("Honey", "Syrup"), ("Jam", "Jelly"), ("Peanut Butter", "Almond Butter"), ("Hummus", "Guacamole"),
        ("Salsa", "Pico de Gallo"), ("Ketchup", "BBQ Sauce"), ("Mustard", "Mayo"), ("Vinegar", "Dressing"),
        ("Olive Oil", "Vegetable Oil"), ("Salt", "Seasoning"), ("Pepper", "Spice"), ("Basil", "Oregano"),
        ("Cinnamon", "Nutmeg"), ("Vanilla", "Almond Extract"), ("Chocolate", "Caramel"), ("Apple", "Pear"),
        ("Orange", "Tangerine"), ("Grape", "Berry"), ("Banana", "Plantain"), ("Mango", "Papaya"),
        ("Watermelon", "Cantaloupe"), ("Strawberry", "Raspberry"), ("Blueberry", "Blackberry"),
        ("Avocado", "Guacamole"), ("Tomato", "Cherry Tomato"), ("Potato", "Sweet Potato"),
        ("Onion", "Shallot"), ("Garlic", "Ginger"), ("Carrot", "Celery"), ("Broccoli", "Cauliflower"),
        ("Spinach", "Kale"), ("Lettuce", "Arugula"), ("Corn", "Peas"), ("Beans", "Lentils"),
        ("Chickpeas", "Edamame"), ("Tofu", "Tempeh"), ("Chicken", "Turkey"), ("Pork", "Ham"),
        ("Lamb", "Goat"), ("Salmon", "Trout"), ("Shrimp", "Prawn"), ("Crab", "Lobster"),
        ("Oyster", "Clam"), ("Calamari", "Octopus"), ("Bacon", "Pancetta"), ("Sausage", "Bratwurst"),
        ("Meatball", "Patty"), ("Kebab", "Skewer"), ("Falafel", "Patty"), ("Granola", "Cereal"),
        ("Oatmeal", "Porridge"), ("Popcorn", "Pretzels"), ("Trail Mix", "Nuts"), ("Chips", "Crisps"),
        ("Crackers", "Breadsticks"), ("Bread", "Roll"), ("Baguette", "Ciabatta"), ("Pita", "Naan"),
        ("Tortilla", "Roti"), ("Risotto", "Paella"), ("Gumbo", "Jambalaya"), ("Chili", "Chowder"),
        ("BBQ Ribs", "Pulled Pork"), ("Fish and Chips", "Fried Fish"), ("Pad Thai", "Lo Mein"),
        ("Butter Chicken", "Tikka Masala"), ("Biryani", "Pulao"), ("Samosa", "Pakora"),
        ("Donut", "Churro"), ("Macaron", "Macaroon"), ("Truffle", "Bonbon"), ("Pudding", "Custard"),
        ("Cheesecake", "Tiramisu"), ("Crepe", "Blintz"), ("Funnel Cake", "Elephant Ear"),
    ])

    add("Objects", [
        ("Phone", "Tablet"), ("Laptop", "Desktop"), ("Keyboard", "Piano"), ("Camera", "Camcorder"),
        ("Watch", "Clock"), ("Glasses", "Sunglasses"), ("Hat", "Cap"), ("Scarf", "Shawl"),
        ("Jacket", "Coat"), ("Shirt", "Blouse"), ("Pants", "Jeans"), ("Shoes", "Sneakers"),
        ("Boots", "Sandals"), ("Sock", "Stocking"), ("Belt", "Suspenders"), ("Tie", "Bow Tie"),
        ("Ring", "Bracelet"), ("Necklace", "Chain"), ("Earring", "Piercing"), ("Wallet", "Purse"),
        ("Backpack", "Suitcase"), ("Umbrella", "Parasol"), ("Flashlight", "Lantern"), ("Candle", "Torch"),
        ("Lamp", "Chandelier"), ("Mirror", "Window"), ("Curtain", "Blind"), ("Pillow", "Cushion"),
        ("Blanket", "Quilt"), ("Sheet", "Towel"), ("Soap", "Shampoo"), ("Toothbrush", "Comb"),
        ("Razor", "Trimmer"), ("Brush", "Broom"), ("Mop", "Vacuum"), ("Bucket", "Basin"),
        ("Sponge", "Cloth"), ("Plate", "Bowl"), ("Cup", "Mug"), ("Fork", "Spoon"),
        ("Knife", "Scissors"), ("Pot", "Pan"), ("Oven", "Microwave"), ("Fridge", "Freezer"),
        ("Blender", "Mixer"), ("Toaster", "Grill"), ("Kettle", "Coffee Maker"), ("Scale", "Ruler"),
        ("Hammer", "Wrench"), ("Screwdriver", "Drill"), ("Ladder", "Stool"), ("Chair", "Stool"),
        ("Table", "Desk"), ("Couch", "Sofa"), ("Bed", "Mattress"), ("Drawer", "Cabinet"),
        ("Shelf", "Rack"), ("Box", "Crate"), ("Bag", "Sack"), ("Bottle", "Jar"),
        ("Can", "Carton"), ("Envelope", "Package"), ("Stamp", "Sticker"), ("Pen", "Pencil"),
        ("Marker", "Crayon"), ("Notebook", "Journal"), ("Book", "Magazine"), ("Newspaper", "Flyer"),
        ("Map", "Chart"), ("Globe", "Atlas"), ("Compass", "GPS"), ("Binoculars", "Telescope"),
        ("Tent", "Canopy"), ("Sleeping Bag", "Bedroll"), ("Rope", "Chain"), ("Hook", "Clip"),
        ("Tape", "Glue"), ("Pin", "Needle"), ("Thread", "Yarn"), ("Button", "Zipper"),
        ("Ball", "Orb"), ("Dice", "Chip"), ("Card", "Ticket"), ("Coin", "Token"),
        ("Key", "Lock"), ("Remote", "Controller"), ("Speaker", "Headphones"), ("Microphone", "Megaphone"),
        ("Battery", "Charger"), ("Cable", "Cord"), ("Plug", "Adapter"), ("Fan", "Heater"),
        ("AC Unit", "Humidifier"), ("Thermostat", "Timer"), ("Alarm", "Bell"), ("Whistle", "Horn"),
        ("Flag", "Banner"), ("Poster", "Sign"), ("Frame", "Stand"), ("Vase", "Pot"),
        ("Sculpture", "Figurine"), ("Toy", "Doll"), ("Puzzle", "Board Game"), ("Balloon", "Kite"),
        ("Skateboard", "Scooter"), ("Bicycle", "Tricycle"), ("Helmet", "Pads"), ("Glove", "Mitten"),
        ("Bat", "Racket"), ("Club", "Stick"), ("Net", "Goal"), ("Whistle", "Flag"),
        ("Medal", "Trophy"), ("Ribbon", "Badge"), ("Mask", "Costume"), ("Wig", "Hat"),
        ("Paintbrush", "Roller"), ("Canvas", "Easel"), ("Palette", "Knife"), ("Clay", "Putty"),
        ("Drone", "Robot"), ("Printer", "Scanner"), ("Router", "Modem"), ("Hard Drive", "USB Drive"),
    ])

    add("Nature", [
        ("Sunrise", "Sunset"), ("Rain", "Drizzle"), ("Storm", "Hurricane"), ("Snow", "Hail"),
        ("Fog", "Mist"), ("Wind", "Breeze"), ("Thunder", "Lightning"), ("Rainbow", "Aurora"),
        ("Cloud", "Smoke"), ("Wave", "Tide"), ("Rock", "Pebble"), ("Sand", "Dust"),
        ("Soil", "Mud"), ("Grass", "Moss"), ("Tree", "Bush"), ("Flower", "Bloom"),
        ("Leaf", "Petal"), ("Root", "Stem"), ("Seed", "Nut"), ("Fruit", "Berry"),
        ("Vine", "Branch"), ("Thorn", "Spike"), ("Cactus", "Succulent"), ("Fern", "Palm"),
        ("Pine", "Cedar"), ("Oak", "Maple"), ("Willow", "Birch"), ("Rose", "Tulip"),
        ("Daisy", "Sunflower"), ("Lily", "Orchid"), ("Coral", "Reef"), ("Shell", "Pearl"),
        ("Starfish", "Seahorse"), ("Dolphin", "Whale"), ("Shark", "Ray"), ("Turtle", "Tortoise"),
        ("Frog", "Toad"), ("Snake", "Lizard"), ("Eagle", "Hawk"), ("Owl", "Crow"),
        ("Sparrow", "Finch"), ("Duck", "Goose"), ("Swan", "Crane"), ("Penguin", "Puffin"),
        ("Bear", "Panda"), ("Wolf", "Fox"), ("Lion", "Tiger"), ("Leopard", "Cheetah"),
        ("Elephant", "Rhino"), ("Giraffe", "Zebra"), ("Deer", "Elk"), ("Moose", "Caribou"),
        ("Rabbit", "Hare"), ("Squirrel", "Chipmunk"), ("Bat", "Rodent"), ("Horse", "Donkey"),
        ("Cow", "Buffalo"), ("Sheep", "Goat"), ("Pig", "Boar"), ("Chicken", "Rooster"),
        ("Bee", "Wasp"), ("Butterfly", "Moth"), ("Ant", "Beetle"), ("Spider", "Scorpion"),
        ("Fish", "Minnow"), ("Eel", "Snake"), ("Crab", "Lobster"), ("Jellyfish", "Anemone"),
        ("Volcano", "Geyser"), ("Glacier", "Iceberg"), ("Cave", "Grotto"), ("Cliff", "Bluff"),
        ("Meadow", "Prairie"), ("Swamp", "Marsh"), ("Riverbank", "Shoreline"), ("Spring", "Brook"),
        ("Pond", "Lagoon"), ("Bay", "Gulf"), ("Strait", "Channel"), ("Reef", "Atoll"),
        ("Dune", "Drift"), ("Canyon", "Ravine"), ("Plateau", "Mesa"), ("Summit", "Peak"),
        ("Crater", "Basin"), ("Grove", "Copse"), ("Orchard", "Vineyard"), ("Field", "Pasture"),
        ("Hedge", "Fence Row"), ("Wildflower", "Weed"), ("Mushroom", "Fungus"), ("Algae", "Seaweed"),
        ("Icicle", "Frost"), ("Puddle", "Pool"), ("Stream", "Creek"), ("Waterfall", "Cascade"),
    ])

    add("Professions", [
        ("Doctor", "Nurse"), ("Surgeon", "Dentist"), ("Therapist", "Counselor"), ("Pharmacist", "Chemist"),
        ("Teacher", "Professor"), ("Tutor", "Coach"), ("Principal", "Dean"), ("Librarian", "Curator"),
        ("Engineer", "Architect"), ("Mechanic", "Technician"), ("Electrician", "Plumber"),
        ("Carpenter", "Mason"), ("Painter", "Decorator"), ("Designer", "Stylist"),
        ("Artist", "Illustrator"), ("Musician", "Composer"), ("Singer", "Dancer"),
        ("Actor", "Director"), ("Writer", "Editor"), ("Reporter", "Anchor"), ("Photographer", "Videographer"),
        ("Chef", "Baker"), ("Barista", "Bartender"), ("Waiter", "Host"), ("Farmer", "Gardener"),
        ("Rancher", "Shepherd"), ("Fisherman", "Sailor"), ("Pilot", "Captain"), ("Driver", "Conductor"),
        ("Mechanic", "Machinist"), ("Soldier", "Officer"), ("Firefighter", "Paramedic"), ("Police Officer", "Detective"),
        ("Lawyer", "Judge"), ("Accountant", "Auditor"), ("Banker", "Teller"), ("Trader", "Broker"),
        ("Manager", "Supervisor"), ("CEO", "Founder"), ("Intern", "Assistant"), ("Secretary", "Receptionist"),
        ("Salesperson", "Marketer"), ("Consultant", "Advisor"), ("Scientist", "Researcher"),
        ("Astronaut", "Astronomer"), ("Biologist", "Chemist"), ("Geologist", "Archaeologist"),
        ("Veterinarian", "Zoologist"), ("Nanny", "Caregiver"), ("Janitor", "Custodian"),
        ("Security Guard", "Bouncer"), ("Lifeguard", "Ranger"), ("Guide", "Interpreter"),
        ("Tailor", "Seamstress"), ("Jeweler", "Goldsmith"), ("Blacksmith", "Welder"),
        ("Programmer", "Developer"), ("Analyst", "Data Scientist"), ("Product Manager", "Project Manager"),
        ("UX Designer", "UI Designer"), ("Streamer", "Influencer"), ("Athlete", "Trainer"),
        ("Referee", "Umpire"), ("Commentator", "Announcer"), ("Magician", "Clown"),
        ("Florist", "Botanist"), ("Butcher", "Deli Worker"), ("Cashier", "Clerk"),
        ("Courier", "Delivery Driver"), ("Travel Agent", "Tour Guide"), ("Hotel Manager", "Concierge"),
        ("Real Estate Agent", "Appraiser"), ("Contractor", "Foreman"), ("Miner", "Driller"),
        ("Factory Worker", "Assembler"), ("Quality Inspector", "Tester"), ("Pilot Instructor", "Flight Attendant"),
        ("Social Worker", "Case Manager"), ("Midwife", "Doula"), ("Optometrist", "Ophthalmologist"),
        ("Chiropractor", "Physiotherapist"), ("Podiatrist", "Orthodontist"), ("Historian", "Archivist"),
        ("Translator", "Linguist"), ("Cartographer", "Surveyor"), ("Meteorologist", "Climatologist"),
    ])

    add("Sports", [
        ("Soccer", "Rugby"), ("Football", "Handball"), ("Basketball", "Netball"), ("Baseball", "Softball"),
        ("Cricket", "Rounders"), ("Tennis", "Badminton"), ("Volleyball", "Beach Volleyball"),
        ("Hockey", "Field Hockey"), ("Ice Hockey", "Curling"), ("Golf", "Mini Golf"),
        ("Bowling", "Billiards"), ("Boxing", "Wrestling"), ("MMA", "Judo"), ("Karate", "Taekwondo"),
        ("Fencing", "Kendo"), ("Archery", "Shooting"), ("Skiing", "Snowboarding"), ("Skating", "Figure Skating"),
        ("Cycling", "BMX"), ("Running", "Sprinting"), ("Marathon", "Triathlon"), ("Swimming", "Diving"),
        ("Surfing", "Windsurfing"), ("Rowing", "Canoeing"), ("Kayaking", "Rafting"), ("Sailing", "Yachting"),
        ("Climbing", "Bouldering"), ("Hiking", "Trekking"), ("Horse Racing", "Polo"), ("Motorsport", "Rally"),
        ("Formula One", "IndyCar"), ("NASCAR", "Stock Car"), ("Drag Racing", "Drifting"),
        ("Skateboarding", "Longboarding"), ("Parkour", "Gymnastics"), ("Cheerleading", "Dance Sport"),
        ("Weightlifting", "Powerlifting"), ("CrossFit", "Calisthenics"), ("Pilates", "Yoga"),
        ("Table Tennis", "Squash"), ("Racquetball", "Pickleball"), ("Lacrosse", "Field Lacrosse"),
        ("Water Polo", "Synchronized Swimming"), ("Biathlon", "Pentathlon"), ("Decathlon", "Heptathlon"),
        ("Shot Put", "Discus"), ("Javelin", "Hammer Throw"), ("Long Jump", "Triple Jump"),
        ("High Jump", "Pole Vault"), ("Hurdles", "Steeplechase"), ("Relay", "Medley"),
        ("Penalty Kick", "Free Kick"), ("Home Run", "Grand Slam"), ("Touchdown", "Field Goal"),
        ("Slam Dunk", "Alley-Oop"), ("Ace", "Smash"), ("Hat Trick", "Brace"),
        ("Knockout", "Submission"), ("Checkmate", "Stalemate"), ("Eagle", "Birdie"),
        ("Strike", "Spare"), ("Bullseye", "Perfect Score"), ("Podium", "Finish Line"),
        ("Warm Up", "Cooldown"), ("Coach", "Captain"), ("Referee", "Linesman"),
        ("Stadium", "Arena"), ("Court", "Field"), ("Track", "Pool"), ("Gym", "Dojo"),
        ("Helmet", "Pads"), ("Jersey", "Uniform"), ("Cleats", "Spikes"), ("Glove", "Mitt"),
        ("Racket", "Bat"), ("Club", "Puck"), ("Ball", "Shuttlecock"), ("Net", "Hoop"),
        ("Goal", "Post"), ("Whistle", "Flag"), ("Medal", "Trophy"), ("League", "Tournament"),
        ("Playoffs", "Finals"), ("Draft", "Trade"), ("Rookie", "Veteran"), ("Underdog", "Favorite"),
    ])

    add("Transport", [
        ("Car", "SUV"), ("Truck", "Van"), ("Bus", "Coach"), ("Taxi", "Rideshare"),
        ("Train", "Tram"), ("Subway", "Metro"), ("Monorail", "Light Rail"), ("Ferry", "Boat"),
        ("Ship", "Cruise Liner"), ("Yacht", "Sailboat"), ("Canoe", "Kayak"), ("Jet", "Plane"),
        ("Helicopter", "Chopper"), ("Glider", "Drone"), ("Rocket", "Shuttle"), ("Bicycle", "Scooter"),
        ("Motorcycle", "Moped"), ("Skateboard", "Longboard"), ("Wheelchair", "Stroller"),
        ("Ambulance", "Fire Truck"), ("Police Car", "Patrol Car"), ("Limousine", "Sedan"),
        ("Convertible", "Coupe"), ("Hatchback", "Wagon"), ("Pickup", "Flatbed"), ("Tractor", "Bulldozer"),
        ("Forklift", "Crane"), ("Excavator", "Loader"), ("Tank", "Armored Vehicle"),
        ("Cable Car", "Gondola"), ("Rickshaw", "Tuk-Tuk"), ("Horse Carriage", "Sleigh"),
        ("Segway", "Hoverboard"), ("Electric Bike", "E-Scooter"), ("Hyperloop", "Maglev"),
        ("Cargo Ship", "Tanker"), ("Submarine", "Diver Propulsion"), ("Spacecraft", "Satellite"),
        ("Hot Air Balloon", "Blimp"), ("Paraglider", "Hang Glider"), ("Snowmobile", "ATV"),
        ("Golf Cart", "Buggy"), ("Race Car", "Go-Kart"), ("Double Decker", "Articulated Bus"),
        ("Freight Train", "Passenger Train"), ("High-Speed Rail", "Bullet Train"),
        ("Airport Shuttle", "Hotel Shuttle"), ("Parking Meter", "Toll Booth"),
        ("Gas Station", "Charging Station"), ("Garage", "Depot"), ("Hangar", "Port"),
        ("Runway", "Taxiway"), ("Harbor", "Marina"), ("Dock", "Pier"), ("Anchor", "Mooring"),
        ("Compass", "Navigation System"), ("Map", "GPS"), ("Ticket", "Pass"), ("Visa", "Passport"),
        ("Luggage", "Carry-On"), ("Seatbelt", "Harness"), ("Airbag", "Brake"), ("Engine", "Motor"),
        ("Wheel", "Tire"), ("Headlight", "Taillight"), ("Horn", "Siren"), ("Mirror", "Camera"),
        ("Windshield", "Window"), ("Roof Rack", "Trailer"), ("Hitch", "Coupler"),
        ("Pedal", "Handlebar"), ("Gear", "Clutch"), ("Accelerator", "Throttle"), ("Steering Wheel", "Joystick"),
    ])

    add("Animals", [
        ("Dog", "Puppy"), ("Cat", "Kitten"), ("Hamster", "Gerbil"), ("Goldfish", "Betta"),
        ("Parrot", "Canary"), ("Horse", "Pony"), ("Cow", "Calf"), ("Pig", "Piglet"),
        ("Sheep", "Lamb"), ("Goat", "Kid"), ("Chicken", "Chick"), ("Duck", "Duckling"),
        ("Goose", "Gosling"), ("Turkey", "Poult"), ("Rabbit", "Bunny"), ("Ferret", "Weasel"),
        ("Otter", "Beaver"), ("Seal", "Walrus"), ("Polar Bear", "Grizzly"), ("Koala", "Sloth"),
        ("Kangaroo", "Wallaby"), ("Platypus", "Echidna"), ("Peacock", "Pheasant"), ("Flamingo", "Crane"),
        ("Parakeet", "Cockatiel"), ("Iguana", "Gecko"), ("Chameleon", "Salamander"), ("Tortoise", "Terrapin"),
        ("Hedgehog", "Porcupine"), ("Raccoon", "Skunk"), ("Squirrel", "Chipmunk"), ("Mouse", "Rat"),
        ("Bat", "Flying Fox"), ("Antelope", "Gazelle"), ("Bison", "Yak"), ("Camel", "Llama"),
        ("Alpaca", "Vicuna"), ("Donkey", "Mule"), ("Hyena", "Jackal"), ("Cheetah", "Jaguar"),
        ("Panther", "Cougar"), ("Gorilla", "Chimpanzee"), ("Orangutan", "Baboon"), ("Monkey", "Lemur"),
        ("Hippo", "Rhino"), ("Walrus", "Manatee"), ("Narwhal", "Beluga"), ("Octopus", "Squid"),
        ("Jellyfish", "Sea Anemone"), ("Starfish", "Urchin"), ("Clownfish", "Angelfish"), ("Shark", "Barracuda"),
        ("Stingray", "Manta Ray"), ("Crocodile", "Alligator"), ("Python", "Boa"), ("Cobra", "Viper"),
        ("Eagle", "Falcon"), ("Vulture", "Condor"), ("Pelican", "Stork"), ("Heron", "Egret"),
        ("Woodpecker", "Kingfisher"), ("Robin", "Blue Jay"), ("Cardinal", "Sparrow"), ("Pigeon", "Dove"),
        ("Crow", "Raven"), ("Magpie", "Jay"), ("Owl", "Nightjar"), ("Swan", "Pelican"),
        ("Dragonfly", "Damselfly"), ("Ladybug", "Beetle"), ("Grasshopper", "Cricket"), ("Caterpillar", "Centipede"),
        ("Snail", "Slug"), ("Earthworm", "Leech"), ("Tarantula", "Wolf Spider"), ("Scorpion", "Tick"),
    ])

    add("Entertainment", [
        ("Movie", "Film"), ("Series", "Miniseries"), ("Documentary", "Biopic"), ("Comedy", "Sitcom"),
        ("Drama", "Melodrama"), ("Thriller", "Suspense"), ("Horror", "Slasher"), ("Fantasy", "Mythology"),
        ("Sci-Fi", "Space Opera"), ("Animation", "Cartoon"), ("Anime", "Manga"), ("Podcast", "Audiobook"),
        ("Concert", "Festival"), ("Album", "EP"), ("Single", "Remix"), ("Music Video", "Lyric Video"),
        ("Theater", "Musical"), ("Opera", "Ballet"), ("Stand-Up", "Improv"), ("Magic Show", "Circus"),
        ("Game Show", "Quiz"), ("Reality TV", "Talent Show"), ("Talk Show", "Interview"), ("News", "Report"),
        ("Trailer", "Teaser"), ("Poster", "Billboard"), ("Premiere", "Screening"), ("Award Show", "Ceremony"),
        ("Oscars", "Grammys"), ("Emmys", "Tonys"), ("Comic Con", "Expo"), ("Fan Meet", "Signing"),
        ("Merch", "Collectible"), ("Action Figure", "Statue"), ("Board Game", "Card Game"),
        ("Video Game", "Mobile Game"), ("RPG", "Strategy Game"), ("Puzzle Game", "Platformer"),
        ("Streaming", "Broadcast"), ("Cable", "Satellite"), ("Subscription", "Rental"), ("Ticket", "Pass"),
        ("Box Office", "Chart"), ("Review", "Rating"), ("Spoiler", "Teaser"), ("Fandom", "Community"),
        ("Cosplay", "Costume"), ("Meme", "Trend"), ("Viral Video", "Challenge"), ("Influencer", "Creator"),
        ("Channel", "Playlist"), ("Livestream", "VOD"), ("Commentary", "Recap"), ("Sequel", "Prequel"),
        ("Reboot", "Remake"), ("Spin-Off", "Crossover"), ("Finale", "Pilot"), ("Season", "Episode"),
        ("Theme Song", "Soundtrack"), ("Director's Cut", "Extended Edition"), ("Credits", "Post-Credits"),
        ("Blockbuster", "Indie Film"), ("Franchise", "Universe"), ("Studio", "Label"), ("Agent", "Manager"),
    ])

    add("Daily Life", [
        ("Morning", "Afternoon"), ("Breakfast", "Brunch"), ("Commute", "Errand"), ("Meeting", "Appointment"),
        ("Email", "Text"), ("Call", "Video Chat"), ("Calendar", "Reminder"), ("Alarm", "Snooze"),
        ("Shower", "Bath"), ("Laundry", "Dry Cleaning"), ("Dishes", "Chores"), ("Cleaning", "Organizing"),
        ("Shopping", "Groceries"), ("Budget", "Expense"), ("Bill", "Invoice"), ("Paycheck", "Bonus"),
        ("Homework", "Study"), ("Exam", "Quiz"), ("Interview", "Orientation"), ("Break", "Vacation"),
        ("Party", "Gathering"), ("Date", "Hangout"), ("Wedding", "Engagement"), ("Birthday", "Anniversary"),
        ("Gift", "Card"), ("Decoration", "Setup"), ("Reservation", "Booking"), ("Check-In", "Checkout"),
        ("Password", "PIN"), ("Login", "Signup"), ("Update", "Upgrade"), ("Backup", "Restore"),
        ("Weather", "Forecast"), ("Umbrella Day", "Heatwave"), ("Traffic", "Detour"), ("Parking", "Ticket"),
        ("Neighbor", "Roommate"), ("Family", "Relative"), ("Friend", "Colleague"), ("Boss", "Client"),
        ("Compliment", "Feedback"), ("Apology", "Excuse"), ("Plan", "Schedule"), ("Goal", "Habit"),
        ("Workout", "Walk"), ("Meditation", "Stretch"), ("Nap", "Sleep In"), ("Early Bird", "Night Owl"),
        ("Recipe", "Meal Prep"), ("Takeout", "Delivery"), ("Leftovers", "Snack"), ("Diet", "Cheat Day"),
        ("Allergy", "Cold"), ("Medicine", "Vitamin"), ("Checkup", "Screening"), ("Insurance", "Claim"),
        ("Newsletter", "Notification"), ("Scroll", "Binge"), ("Unplug", "Digital Detox"), ("Journal", "Planner"),
        ("To-Do List", "Checklist"), ("Deadline", "Extension"), ("Promotion", "Raise"), ("Side Hustle", "Freelance"),
        ("Rent", "Mortgage"), ("Lease", "Contract"), ("Move-In", "Move-Out"), ("Furniture", "Appliance"),
        ("Repair", "Maintenance"), ("DIY", "Handyman"), ("Gardening", "Landscaping"), ("Pet Care", "Vet Visit"),
        ("Childcare", "Pickup"), ("School Run", "Carpool"), ("Volunteer", "Donation"), ("Holiday", "Weekend"),
    ])

    add("Home", [
        ("Living Room", "Family Room"), ("Kitchen", "Pantry"), ("Bedroom", "Guest Room"), ("Bathroom", "Powder Room"),
        ("Dining Table", "Coffee Table"), ("Sofa", "Loveseat"), ("Rug", "Carpet"), ("Curtain", "Drape"),
        ("Blinds", "Shades"), ("Light Switch", "Dimmer"), ("Outlet", "Extension Cord"), ("Thermostat", "Vent"),
        ("Smoke Detector", "Carbon Monoxide Alarm"), ("Doorbell", "Intercom"), ("Lock", "Deadbolt"),
        ("Garage Door", "Gate"), ("Mailbox", "Package Box"), ("Welcome Mat", "Doormat"), ("Coat Rack", "Hook"),
        ("Shoe Rack", "Closet"), ("Dresser", "Nightstand"), ("Wardrobe", "Armoire"), ("Bookshelf", "Cabinet"),
        ("Desk Lamp", "Floor Lamp"), ("Ceiling Fan", "Chandelier"), ("Wall Art", "Photo Frame"),
        ("Vase", "Centerpiece"), ("Throw Blanket", "Quilt"), ("Pillowcase", "Duvet"), ("Mattress Topper", "Sheet Set"),
        ("Shower Curtain", "Bath Mat"), ("Towel Rack", "Soap Dish"), ("Toothbrush Holder", "Tumbler"),
        ("Trash Can", "Recycling Bin"), ("Laundry Basket", "Hamper"), ("Ironing Board", "Steamer"),
        ("Vacuum Bag", "Filter"), ("Dish Rack", "Cutting Board"), ("Spice Rack", "Utensil Holder"),
        ("Cookie Jar", "Bread Box"), ("Wine Rack", "Bar Cart"), ("Ice Tray", "Pitcher"), ("Serving Tray", "Platter"),
        ("Smart Speaker", "Smart Display"), ("Security Camera", "Door Sensor"), ("Router", "Mesh Node"),
        ("Houseplant", "Succulent"), ("Aquarium", "Terrarium"), ("Fireplace", "Space Heater"), ("Humidifier", "Diffuser"),
        ("Air Purifier", "Dehumidifier"), ("Tool Box", "Workbench"), ("Ladder", "Step Stool"), ("Flashlight Drawer", "Junk Drawer"),
    ])

    add("Events", [
        ("Birthday Party", "Surprise Party"), ("Wedding Reception", "Engagement Party"), ("Baby Shower", "Gender Reveal"),
        ("Graduation", "Commencement"), ("Prom", "Homecoming"), ("Reunion", "Meetup"), ("Conference", "Summit"),
        ("Workshop", "Seminar"), ("Hackathon", "Competition"), ("Fundraiser", "Charity Gala"), ("Parade", "March"),
        ("Festival", "Fair"), ("Carnival", "Circus"), ("Concert", "Tour Stop"), ("Premiere", "Opening Night"),
        ("Awards Night", "Banquet"), ("Holiday Party", "Office Party"), ("Housewarming", "Open House"),
        ("Block Party", "Neighborhood BBQ"), ("Picnic", "Potluck"), ("Campout", "Retreat"), ("Road Trip", "Getaway"),
        ("Vacation", "Staycation"), ("Honeymoon", "Anniversary Trip"), ("Sports Game", "Championship"),
        ("Match Day", "Tailgate"), ("Book Launch", "Signing Event"), ("Art Show", "Gallery Opening"),
        ("Fashion Show", "Runway Event"), ("Trade Show", "Expo Booth"), ("Product Launch", "Keynote"),
        ("Press Conference", "Briefing"), ("Town Hall", "Forum"), ("Debate", "Panel"), ("Ceremony", "Ritual"),
        ("Memorial", "Tribute"), ("Funeral", "Wake"), ("Baptism", "Confirmation"), ("Bar Mitzvah", "Quinceañera"),
        ("New Year's Eve", "Countdown"), ("Fireworks", "Light Show"), ("Eclipse Viewing", "Stargazing Night"),
        ("Flash Mob", "Performance"), ("Protest", "Rally"), ("Election Night", "Watch Party"),
        ("Game Night", "Trivia Night"), ("Karaoke Night", "Open Mic"), ("Dance Party", "Rave"),
        ("Costume Party", "Masquerade"), ("Pool Party", "Beach Day"), ("Snow Day", "Ski Trip"),
        ("Farmers Market", "Flea Market"), ("Grand Opening", "Soft Launch"), ("Closing Sale", "Clearance Event"),
    ])

    add("Time", [
        ("Second", "Minute"), ("Hour", "Moment"), ("Day", "Date"), ("Week", "Weekend"),
        ("Month", "Season"), ("Year", "Decade"), ("Century", "Era"), ("Past", "History"),
        ("Present", "Now"), ("Future", "Tomorrow"), ("Morning", "Dawn"), ("Noon", "Midday"),
        ("Afternoon", "Evening"), ("Night", "Midnight"), ("Sunrise", "Daybreak"), ("Sunset", "Dusk"),
        ("Spring", "Autumn"), ("Summer", "Winter"), ("Holiday", "Vacation Day"), ("Deadline", "Due Date"),
        ("Schedule", "Timeline"), ("Delay", "Pause"), ("Early", "Late"), ("Punctual", "Tardy"),
        ("Daily", "Weekly"), ("Monthly", "Annual"), ("Temporary", "Permanent"), ("Brief", "Extended"),
        ("Instant", "Gradual"), ("Recent", "Ancient"), ("Modern", "Classic"), ("Vintage", "Retro"),
        ("Countdown", "Timer"), ("Stopwatch", "Clock"), ("Time Zone", "Daylight Saving"), ("Calendar Year", "Fiscal Year"),
        ("Quarter", "Semester"), ("Term", "Session"), ("Interval", "Duration"), ("Phase", "Period"),
        ("Era", "Age"), ("Generation", "Epoch"), ("Anniversary", "Milestone"), ("Centennial", "Bicentennial"),
    ])

    add("Seasons", [
        ("Spring Bloom", "Cherry Blossom"), ("Summer Heat", "Heatwave"), ("Autumn Leaves", "Fall Foliage"),
        ("Winter Snow", "Blizzard"), ("Rainy Season", "Monsoon"), ("Dry Season", "Drought"), ("Harvest", "Planting"),
        ("Migration", "Hibernation"), ("Flu Season", "Allergy Season"), ("Holiday Season", "Back to School"),
        ("Spring Cleaning", "Winter Prep"), ("Daylight", "Darkness"), ("Thaw", "Freeze"), ("Bloom", "Wilting"),
        ("Greenhouse Season", "Garden Season"), ("Ski Season", "Beach Season"), ("Carnival Season", "Festival Season"),
        ("Tax Season", "Award Season"), ("Sports Season", "Offseason"), ("Premiere Season", "Rerun Season"),
        ("Shoulder Season", "Peak Season"), ("Off-Peak", "Rush Hour"), ("Golden Hour", "Blue Hour"),
        ("Solstice", "Equinox"), ("Full Moon", "New Moon"), ("Tide Season", "Storm Season"),
    ])

    add("Outdoors", [
        ("Camping", "Glamping"), ("Hiking", "Trail Run"), ("Climbing", "Bouldering"), ("Fishing", "Fly Fishing"),
        ("Hunting", "Tracking"), ("Birdwatching", "Wildlife Spotting"), ("Stargazing", "Astrophotography"),
        ("Picnic", "BBQ"), ("Bonfire", "Campfire"), ("Canoeing", "Kayaking"), ("Rafting", "Tubing"),
        ("Snorkeling", "Scuba Diving"), ("Surfing", "Bodyboarding"), ("Sailing", "Windsurfing"), ("Kitesurfing", "Parasailing"),
        ("Snowboarding", "Skiing"), ("Sledding", "Tubing"), ("Ice Skating", "Snowshoeing"), ("Mountain Biking", "Gravel Riding"),
        ("Rock Climbing", "Via Ferrata"), ("Caving", "Spelunking"), ("Orienteering", "Geocaching"), ("Foraging", "Mushroom Hunting"),
        ("Gardening", "Landscaping"), ("Composting", "Mulching"), ("Greenhouse", "Raised Bed"), ("Tree Planting", "Reforestation"),
        ("Beach Day", "Lake Day"), ("Desert Trek", "Dune Walk"), ("Jungle Trek", "Safari"), ("National Park", "State Park"),
        ("Scenic Drive", "Road Trip"), ("Rest Stop", "Viewpoint"), ("Trail Marker", "Summit Sign"), ("Park Bench", "Gazebo"),
        ("Pavilion", "Shelter"), ("Ranger Station", "Visitor Center"), ("Camp Stove", "Fire Pit"), ("Tent Stake", "Guyline"),
        ("Sleeping Pad", "Camp Cot"), ("Headlamp", "Lantern"), ("Bug Spray", "Sunscreen"), ("Rain Jacket", "Windbreaker"),
        ("Daypack", "Hydration Pack"), ("Trekking Pole", "Walking Stick"), ("Compass Navigation", "Trail Map"),
        ("Wildflower Walk", "Nature Trail"), ("Boardwalk", "Nature Path"), ("Observation Deck", "Wildlife Blind"),
    ])

    add("General", [
        ("Anchor", "Mooring"), ("Apron", "Smock"), ("Arch", "Vault"), ("Armor", "Shield"),
        ("Atlas", "Gazetteer"), ("Badge", "Emblem"), ("Balcony", "Veranda"), ("Bamboo", "Cane"),
        ("Banner", "Pennant"), ("Barrel", "Cask"), ("Basket", "Hamper"), ("Beacon", "Signal"),
        ("Beaker", "Flask"), ("Bench", "Pew"), ("Blazer", "Cardigan"), ("Bonnet", "Hood"),
        ("Bookmark", "Placeholder"), ("Boulder", "Monolith"), ("Brochure", "Leaflet"), ("Broomstick", "Mop Handle"),
        ("Bubble", "Globule"), ("Buckle", "Clasp"), ("Bulldozer", "Grader"), ("Bunker", "Pillbox"),
        ("Cabin", "Chalet"), ("Cactus", "Agave"), ("Candlestick", "Candelabra"), ("Canopy", "Awning"),
        ("Caravan", "Convoy"), ("Carnival", "Fairground"), ("Carton", "Crate"), ("Cavern", "Grotto"),
        ("Cedar", "Spruce"), ("Chalk", "Charcoal"), ("Chandelier", "Sconce"), ("Chapel", "Oratory"),
        ("Chest", "Trunk"), ("Chimney", "Flue"), ("Chisel", "Gouge"), ("Cinnamon Roll", "Pastry Swirl"),
        ("Cleaver", "Hatchet"), ("Cloak", "Cape"), ("Clownfish", "Damselfish"), ("Coaster", "Placemat"),
        ("Cobblestone", "Paving"), ("Compass Rose", "Wind Rose"), ("Concert Hall", "Opera House"),
        ("Copper", "Bronze"), ("Coral Reef", "Atoll"), ("Cornfield", "Wheat Field"), ("Cottage", "Bungalow"),
        ("Cotton", "Linen"), ("Couch Cushion", "Throw Pillow"), ("Crater Lake", "Caldera"), ("Crescent", "Half Moon"),
        ("Crosswalk", "Pedestrian Lane"), ("Crowbar", "Pry Bar"), ("Crystal", "Gemstone"), ("Cupola", "Dome"),
        ("Currant", "Gooseberry"), ("Cypress", "Juniper"), ("Dagger", "Stiletto"), ("Daisy Chain", "Garland"),
        ("Dandelion", "Thistle"), ("Deck", "Patio"), ("Delta", "Estuary"), ("Den", "Lair"),
        ("Desk Organizer", "Tray"), ("Dew", "Condensation"), ("Diamond", "Rhombus"), ("Diesel", "Petrol"),
        ("Dining Hall", "Canteen"), ("Dockyard", "Shipyard"), ("Dollhouse", "Miniature"), ("Door Knob", "Handle"),
        ("Dragonfly Wing", "Insect Wing"), ("Driftwood", "Flotsam"), ("Drizzle", "Sprinkle"), ("Dune Buggy", "ATV"),
        ("Dustpan", "Brush Set"), ("Eagle Nest", "Eyrie"), ("Earbuds", "Earphones"), ("Echo", "Reverberation"),
        ("Eclipse", "Transit"), ("Elm", "Ash Tree"), ("Embroidery", "Needlework"), ("Ember", "Cinder"),
        ("Engine Block", "Motor Block"), ("Envelope Seal", "Wax Stamp"), ("Eucalyptus", "Mint Leaf"),
        ("Evergreen", "Conifer"), ("Fabric Softener", "Detergent"), ("Falcon", "Kestrel"), ("Farmhouse", "Grange"),
        ("Feather", "Quill"), ("Fence Post", "Gate Post"), ("Ferryboat", "Water Taxi"), ("Fiddle", "Violin"),
        ("Fieldstone", "Flagstone"), ("Fig", "Date Fruit"), ("Fireplace Mantel", "Hearth"), ("Fjord", "Inlet"),
        ("Flagpole", "Mast"), ("Flannel", "Fleece"), ("Flash Drive", "Memory Stick"), ("Flint", "Spark Stone"),
        ("Floodplain", "Wetland"), ("Flute", "Recorder"), ("Foghorn", "Siren"), ("Footbridge", "Walkway"),
        ("Forest Path", "Woodland Trail"), ("Fossil", "Relic"), ("Fountain Pen", "Ballpoint"), ("Foxglove", "Bluebell"),
        ("Freckle", "Mole"), ("Frostbite", "Chilblain"), ("Funnel Cloud", "Waterspout"), ("Furnace", "Kiln"),
        ("Galleon", "Frigate"), ("Gargoyle", "Grotesque"), ("Gazebo", "Bandstand"), ("Gearshift", "Lever"),
        ("Geode", "Nodule"), ("Geyser Basin", "Hot Spring"), ("Gingham", "Plaid"), ("Glacier Lake", "Moraine Lake"),
        ("Glassware", "Stemware"), ("Glove Box", "Compartment"), ("Goldfish Bowl", "Terrarium"), ("Granite", "Marble"),
        ("Grappling Hook", "Anchor Hook"), ("Gravel Path", "Dirt Road"), ("Greenhouse Gas", "Carbon Output"),
        ("Griddle", "Skillet"), ("Grove", "Copse"), ("Guitar Pick", "Plectrum"), ("Gull", "Tern"),
        ("Hailstone", "Sleet"), ("Hammerhead", "Mallet Head"), ("Handrail", "Banister"), ("Harpsichord", "Clavichord"),
        ("Hatchback", "Sedan"), ("Hazelnut", "Chestnut"), ("Headboard", "Footboard"), ("Heather", "Heath"),
        ("Hedgehog Spine", "Porcupine Quill"), ("Helix", "Spiral"), ("Hemlock", "Yew"), ("Heron", "Crane Bird"),
        ("Highland", "Lowland"), ("Holly", "Ivy"), ("Honeycomb", "Beehive"), ("Horizon", "Skyline"),
        ("Hornet", "Yellowjacket"), ("Horse Stable", "Barn Stall"), ("Hot Spring", "Thermal Pool"),
        ("Hourglass", "Sand Timer"), ("Hubcap", "Wheel Cover"), ("Hummingbird", "Sunbird"), ("Hurricane Eye", "Storm Center"),
        ("Ice Floe", "Ice Sheet"), ("Icicle", "Frost Spike"), ("Inkwell", "Ink Pot"), ("Inlet", "Cove"),
        ("Iron Gate", "Wrought Gate"), ("Ivory", "Bone White"), ("Jackknife", "Pocket Knife"), ("Jasmine", "Lilac"),
        ("Jetty", "Breakwater"), ("Jigsaw", "Puzzle Piece"), ("Juniper Berry", "Allspice"), ("Kaleidoscope", "Prism"),
        ("Keel", "Hull"), ("Kettlebell", "Dumbbell"), ("Keychain", "Lanyard"), ("Kingfisher", "Heron"),
        ("Kitchen Island", "Countertop"), ("Kite String", "Twine"), ("Knapsack", "Rucksack"), ("Labyrinth", "Maze"),
        ("Lagoon", "Bayou"), ("Lark", "Warbler"), ("Lava Field", "Ash Plain"), ("Lawn Mower", "Trimmer"),
        ("Leather", "Suede"), ("Ledger", "Register"), ("Lemon Zest", "Orange Peel"), ("Library Stack", "Archive Shelf"),
        ("Lighthouse Beam", "Searchlight"), ("Lilac Bush", "Lavender Bush"), ("Lime", "Key Lime"), ("Linen Closet", "Pantry Shelf"),
        ("Lizard", "Gecko"), ("Loaf Pan", "Cake Tin"), ("Lobster Trap", "Crab Pot"), ("Locksmith", "Key Maker"),
        ("Locust", "Grasshopper"), ("Loom", "Spinning Wheel"), ("Lotus", "Water Lily"), ("Lumber", "Timber"),
    ])

    return dedupe_pairs(raw)


def movie_pairs_unique(titles: list[str], category: str, target: int) -> list[tuple[str, str, str]]:
    """Pair unique titles so each movie name appears at most once in the pack."""
    unique: list[str] = []
    seen: set[str] = set()
    for title in titles:
        key = title.casefold().strip()
        if not key or key in seen:
            continue
        seen.add(key)
        unique.append(title.strip())

    needed = target * 2
    if len(unique) < needed:
        raise ValueError(f"Need {needed} unique titles for {target} pairs, found {len(unique)}")

    selected = unique[:needed]
    first_half = selected[:target]
    second_half = selected[target:needed]
    return [(insider, mismatch, category) for insider, mismatch in zip(first_half, second_half)]


def build_general(target: int = 1000) -> list[tuple[str, str, str]]:
    seed = load_existing_general()
    extras = general_extra_pairs()
    combined = dedupe_pairs(seed + extras)
    pairs = unique_word_pairs(combined, target)
    if len(pairs) < target:
        raise ValueError(f"General pack needs {target} unique-word pairs, generated {len(pairs)}")
    return pairs


def validate_no_repeated_words(pairs: list[tuple[str, str, str]], pack_name: str) -> None:
    words = [word for insider, mismatch, _ in pairs for word in (insider, mismatch)]
    if len(words) != len({word.casefold() for word in words}):
        raise ValueError(f"{pack_name} contains repeated words")


# Hollywood pack uses plot-similar curated pairs from build_hollywood.py.

POP_CULTURE = [
    ("Taylor Swift", "Olivia Rodrigo"), ("Beyoncé", "Rihanna"), ("Drake", "Kendrick Lamar"),
    ("Eminem", "50 Cent"), ("Lady Gaga", "Madonna"), ("Ariana Grande", "Dua Lipa"),
    ("Billie Eilish", "Lorde"), ("Harry Styles", "Zayn Malik"), ("BTS", "Blackpink"),
    ("Stranger Things", "Dark"), ("Breaking Bad", "Better Call Saul"), ("Game of Thrones", "House of the Dragon"),
    ("The Office", "Parks and Recreation"), ("Friends", "How I Met Your Mother"), ("Seinfeld", "Curb Your Enthusiasm"),
    ("The Simpsons", "Family Guy"), ("South Park", "Rick and Morty"), ("Avatar: The Last Airbender", "Legend of Korra"),
    ("Marvel Cinematic Universe", "DC Extended Universe"), ("Star Wars", "Star Trek"),
    ("Harry Potter", "Percy Jackson"), ("Lord of the Rings", "Game of Thrones"),
    ("Barbie", "Bratz"), ("Hot Wheels", "Matchbox"), ("LEGO", "Mega Bloks"), ("Nintendo", "Sega"),
    ("PlayStation", "Xbox"), ("Fortnite", "Apex Legends"), ("Minecraft", "Roblox"),
    ("Among Us", "Fall Guys"), ("Pokémon", "Digimon"), ("Naruto", "Bleach"), ("One Piece", "Dragon Ball"),
    ("Attack on Titan", "Demon Slayer"), ("My Hero Academia", "Jujutsu Kaisen"), ("Studio Ghibli", "Pixar"),
    ("Disney", "DreamWorks"), ("Netflix", "Hulu"), ("Spotify", "Apple Music"), ("YouTube", "TikTok"),
    ("Instagram", "Snapchat"), ("Twitter", "Threads"), ("Facebook", "LinkedIn"), ("Reddit", "Discord"),
    ("Amazon", "eBay"), ("Apple", "Samsung"), ("Google", "Microsoft"), ("Tesla", "Rivian"),
    ("Starbucks", "Dunkin"), ("McDonald's", "Burger King"), ("KFC", "Popeyes"), ("Coca-Cola", "Pepsi"),
    ("Nike", "Adidas"), ("Gucci", "Prada"), ("Chanel", "Dior"), ("Rolex", "Omega"),
    ("Oscars", "Golden Globes"), ("Grammys", "Billboard Awards"), ("Met Gala", "Coachella"),
    ("Comic-Con", "E3"), ("Super Bowl", "World Cup"), ("Olympics", "Commonwealth Games"),
    ("Wimbledon", "US Open"), ("Formula 1", "NASCAR"), ("WWE", "UFC"), ("NBA", "WNBA"),
    ("Premier League", "La Liga"), ("Champions League", "Europa League"), (" IPL", "BBL"),
    ("Virat Kohli", "Rohit Sharma"), ("MS Dhoni", "Yuvraj Singh"), ("Lionel Messi", "Cristiano Ronaldo"),
    ("LeBron James", "Stephen Curry"), ("Serena Williams", "Venus Williams"), ("Roger Federer", "Rafael Nadal"),
    ("Tom Holland", "Timothée Chalamet"), ("Zendaya", "Florence Pugh"), ("Robert Downey Jr.", "Chris Evans"),
    ("Scarlett Johansson", "Brie Larson"), ("Ryan Reynolds", "Hugh Jackman"), ("Dwayne Johnson", "John Cena"),
    ("Kim Kardashian", "Kylie Jenner"), ("Elon Musk", "Jeff Bezos"), ("Mark Zuckerberg", "Jack Dorsey"),
    ("MrBeast", "PewDiePie"), ("Charli D'Amelio", "Addison Rae"), ("Khaby Lame", "Bella Poarch"),
    ("Wednesday", "Euphoria"), ("Squid Game", "Alice in Borderland"), ("The Crown", "The Queen's Gambit"),
    ("Bridgerton", "Downton Abbey"), ("Sherlock", "Luther"), ("Peaky Blinders", "Boardwalk Empire"),
    ("The Mandalorian", "Andor"), ("WandaVision", "Loki"), ("Moon Knight", "Ms. Marvel"),
    ("Encanto", "Turning Red"), ("Frozen", "Tangled"), ("Moana", "Brave"), ("Coco", "Soul"),
    ("Inside Out", "Elemental"), ("Zootopia", "Sing"), ("Minions", "Despicable Me"),
    ("Barbie Movie", "Oppenheimer"), ("Dune", "Foundation"), ("The Last of Us", "The Walking Dead"),
    ("Succession", "Billions"), ("Yellowstone", "1883"), ("Ted Lasso", "Shrinking"),
    ("Abbott Elementary", "Brooklyn Nine-Nine"), ("Modern Family", "Schitt's Creek"),
    ("The Big Bang Theory", "Young Sheldon"), ("Grey's Anatomy", "House"), ("CSI", "NCIS"),
    ("Survivor", "Big Brother"), ("The Bachelor", "Love Island"), ("American Idol", "The Voice"),
    ("Dancing with the Stars", "Strictly Come Dancing"), ("Jeopardy!", "Wheel of Fortune"),
    ("SNL", "Mad TV"), ("Daily Show", "Colbert Report"), ("John Wick", "James Bond"),
    ("Mission Impossible", "Bourne"), ("Fast & Furious", "Need for Speed"), ("Transformers", "Pacific Rim"),
    ("Jurassic Park", "King Kong"), ("Godzilla", "Kong"), ("Alien", "Predator"),
    ("Avatar", "Pandora"), ("Matrix", "Tron"), ("Blade Runner", "Ghost in the Shell"),
    ("Cyberpunk", "Steampunk"), ("Vaporwave", "Synthwave"), ("Meme", "Viral Trend"),
    ("Hashtag", "Challenge"), ("Selfie", "Reel"), ("Podcast", "Audiobook"), ("Kindle", "Audible"),
    ("AirPods", "Beats"), ("iPad", "Surface"), ("MacBook", "Chromebook"), ("Alexa", "Siri"),
    ("ChatGPT", "Gemini"), ("OpenAI", "Anthropic"), ("Uber", "Lyft"), ("Airbnb", "Booking.com"),
    ("DoorDash", "Uber Eats"), ("Zoom", "Teams"), ("Slack", "Discord"), ("Notion", "Evernote"),
    ("Canva", "Adobe Express"), ("Photoshop", "GIMP"), ("Final Cut", "Premiere Pro"),
    ("Spotify Wrapped", "Apple Replay"), ("Met Gala Look", "Red Carpet"), ("Cosplay", "LARP"),
    ("Fanfiction", "Headcanon"), ("Ship", "OTP"), ("Spoiler", "Leak"), ("Remake", "Reboot"),
    ("Cover Song", "Remix"), ("Vinyl", "Cassette"), ("CD", "Streaming"), ("Blockbuster", "Netflix Mailer"),
    ("MySpace", "Friendster"), ("Vine", "Musical.ly"), ("Flash Mob", "Silent Disco"),
    ("Escape Room", "Laser Tag"), ("Paintball", "Airsoft"), ("Comic Book", "Graphic Novel"),
    ("Manga", "Manhwa"), ("K-Pop", "J-Pop"), ("Bollywood Dance", "Hip Hop"), ("Tap Dance", "Ballet"),
    ("Stand-Up Special", "Roast"), ("Improv Show", "Open Mic"), ("Street Art", "Graffiti"),
    ("NFT", "Crypto"), ("Bitcoin", "Ethereum"), ("Meme Stock", "Index Fund"), ("Reality TV", "Docuseries"),
    ("True Crime", "Cold Case"), ("Paranormal", "Conspiracy"), ("ASMR", "Mukbang"), ("Unboxing", "Haul"),
    ("Reaction Video", "Commentary"), ("Speedrun", "Let's Play"), ("Esports", "LAN Party"),
    ("Comic Strip", "Webtoon"), ("Fan Art", "Commission"), ("Convention", "Meetup"),
    ("Merch Drop", "Limited Edition"), ("Sneaker Drop", "Hypebeast"), ("Thrift Flip", "Vintage Find"),
    ("Aesthetic", "Vibe"), ("Core", "Era"), ("Main Character", "Side Character"), ("Plot Twist", "Cliffhanger"),
    ("Finale", "Spin-Off"), ("Crossover", "Multiverse"), ("Easter Egg", "Cameo"), ("Stan", "Hater"),
    ("Glow Up", "Makeover"), ("Soft Launch", "Hard Launch"), ("BeReal", "Snap Map"), ("Filter", "Face Tune"),
    ("Influencer Trip", "Brand Deal"), ("Cancel Culture", "Comeback Tour"), ("Award Snub", "Sweep"),
    ("Box Office Hit", "Streaming Hit"), ("Binge Watch", "Weekly Release"), ("Season Finale", "Midseason Break"),
    ("Pilot Episode", "Series Finale"), ("Recast", "Reboot Cast"), ("Theme Park", "Water Park"),
    ("Roller Coaster", "Ferris Wheel"), ("Arcade", "Bowling Alley"), ("Karaoke Bar", "Comedy Club"),
    ("Food Truck", "Pop-Up"), ("Farmers Market", "Night Market"), ("Food Festival", "Wine Tasting"),
    ("Book Club", "Watch Party"), ("Fantasy League", "Bracket"), ("March Madness", "Fantasy Draft"),
    ("Trading Card", "Collectible"), ("Funko Pop", "Action Figure"), ("LEGO Set", "Model Kit"),
    ("Coloring Book", "Sticker Book"), ("Board Game Night", "Trivia Night"), ("Murder Mystery", "Escape Game"),
    ("Theme Costume", "Group Costume"), ("Holiday Special", "Clip Show"), ("Afterparty", "Premiere Night"),
    ("Red Carpet", "Press Junket"), ("Fan Cam", "Paparazzi"), ("Autograph", "Selfie Line"),
    ("Limited Drop", "Restock"), ("Collab", "Crossover Brand"), ("Merch Table", "VIP Pass"),
    ("Fandom Name", "Ship Name"), ("Headliner", "Opening Act"), ("Encore", "Surprise Guest"),
    ("Album Drop", "Single Release"), ("World Tour", "Stadium Tour"), ("Festival Headliner", "Side Stage"),
    ("Viral Dance", "Dance Challenge"), ("Sound Trend", "Remix Trend"), ("Filter Trend", "CapCut Template"),
    ("Billie Eilish", "Clairo"), ("Doja Cat", "Ice Spice"), ("Timothée Chalamet", "Austin Butler"),
    ("Florence Pugh", "Saoirse Ronan"), ("Pedro Pascal", "Oscar Isaac"), ("Zendaya", "Halle Bailey"),
    ("Sabrina Carpenter", "Olivia Rodrigo"), ("Charli XCX", "Chappell Roan"),     ("Bad Bunny", "Feid"), ("Rosalia", "Karol G"),
]

POP_CULTURE_FIXED: list[tuple[str, str, str]] = []
for item in POP_CULTURE:
    if isinstance(item, tuple) and len(item) == 2:
        POP_CULTURE_FIXED.append((item[0], item[1], "Pop Culture"))
    elif isinstance(item, str):
        continue


def write_catalog(pack_ids: list[tuple[str, str]]) -> None:
    catalog = {
        "packs": [
            {"id": pack_id, "displayName": display_name, "resourceName": pack_id}
            for pack_id, display_name in pack_ids
        ]
    }
    path = OUT_DIR / "catalog.json"
    path.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {path.name}")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    general = build_general(1000)
    validate_no_repeated_words(general, "general")
    write_pack("general", "General", general)

    build_hollywood = DATA_DIR / "build_hollywood.py"
    subprocess.run([sys.executable, str(build_hollywood)], check=True)

    hollywood = load_similar_pairs_file("hollywood_pairs.json", "Hollywood")
    validate_no_repeated_words(hollywood, "hollywood_movies")
    if len(hollywood) != 250:
        raise ValueError(f"Hollywood pack needs 250 pairs, generated {len(hollywood)}")
    write_pack("hollywood_movies", "Hollywood Movies & Series", hollywood)

    build_indian_pop = DATA_DIR / "build_indian_pop_culture.py"
    subprocess.run([sys.executable, str(build_indian_pop)], check=True)

    indian_pop = load_similar_pairs_file("indian_pop_culture_pairs.json", "Indian Pop Culture")
    validate_no_repeated_words(indian_pop, "indian_pop_culture")
    if len(indian_pop) != 500:
        raise ValueError(f"Indian pop culture pack needs 500 pairs, generated {len(indian_pop)}")
    write_pack("indian_pop_culture", "Indian Pop Culture", indian_pop)

    pop_pairs = unique_word_pairs(dedupe_pairs(POP_CULTURE_FIXED), 250)
    if len(pop_pairs) < 250:
        raise ValueError(f"Pop culture needs 250 unique-word pairs, generated {len(pop_pairs)}")
    validate_no_repeated_words(pop_pairs, "pop_culture")
    write_pack("pop_culture", "Pop Culture", pop_pairs)

    write_catalog([
        ("general", "General"),
        ("hollywood_movies", "Hollywood Movies & Series"),
        ("indian_pop_culture", "Indian Pop Culture"),
        ("pop_culture", "Pop Culture"),
    ])


if __name__ == "__main__":
    main()
