from PIL import Image
import os

try:
    # Load the image
    img = Image.open("assets/images/icon.png")
    img = img.convert("RGBA")
    datas = img.getdata()

    new_data = []
    # Let's see what colors are in the corners to assume as background
    bg_color = datas[0]
    
    # We will make pixels matching bg_color transparent, and others white
    # Since it's a simple icon, we might need a threshold
    for item in datas:
        # Check if the pixel is close to background color
        # Euclidean distance
        dist = sum((item[i] - bg_color[i]) ** 2 for i in range(3))
        if dist < 2000: # Threshold for background
            new_data.append((255, 255, 255, 0)) # Transparent
        else:
            new_data.append((255, 255, 255, 255)) # Solid white

    img.putdata(new_data)
    
    # Ensure drawable directory exists
    os.makedirs("android/app/src/main/res/drawable", exist_ok=True)
    img.save("android/app/src/main/res/drawable/ic_notification.png", "PNG")
    print("Notification icon created successfully at android/app/src/main/res/drawable/ic_notification.png")
except Exception as e:
    print(f"Error: {e}")
