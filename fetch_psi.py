import requests
from datetime import datetime
import time


WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbxtpP8INGvw0o_n41D3cbTNzKNl0dnxPjOudg7Ac8jFoCVxPs06XBRDsE0zYhVKCkjmSg/exec"
API_KEY = "AIzaSyAZ0joOqb5bq39UJNZzG_zuVDAj4teuVNc"

DATE = datetime.now().strftime("%d/%m/%Y")

with open("urls.txt") as f:
    urls = [line.strip() for line in f if line.strip()]

for url in urls:
    print(f"Checking {url}")
    result = {}
    for strategy in ["mobile", "desktop"]:
        try:
            r = requests.get(
                "https://www.googleapis.com/pagespeedonline/v5/runPagespeed",
                params={
                    "url": url,
                    "strategy": strategy,
                    "category": "performance",
                    "key": API_KEY,
                },
                timeout=60
            )
            r.raise_for_status()
            data = r.json()
            score = data.get("lighthouseResult", {}).get("categories", {}).get("performance", {}).get("score", None)
            result[strategy] = round(score * 100) if score is not None else "NA"
        except Exception as e:
            print(f"⚠️ {strategy} failed for {url}: {e}")
            result[strategy] = "NA"
        time.sleep(1)

    payload = {
        "date": DATE,
        "url": url,
        "mobile": result["mobile"],
        "desktop": result["desktop"]
    }

    try:
        response = requests.post(WEBHOOK_URL, json=payload)
        print(f"✅ Sent: {response.text}")
    except Exception as e:
        print(f"❌ Failed to send to Sheet: {e}")