
import os

def replace_imports(directory, old_package, new_package):
    count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        content = f.read()
                    
                    if old_package in content:
                        new_content = content.replace(old_package, new_package)
                        with open(path, "w", encoding="utf-8") as f:
                            f.write(new_content)
                        print(f"Updated {path}")
                        count += 1
                except Exception as e:
                    print(f"Error processing {path}: {e}")
    print(f"Total files updated: {count}")

if __name__ == "__main__":
    replace_imports("packages", "package:waterbus/", "package:bb_meet/")
