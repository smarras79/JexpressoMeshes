import os
import re

def replace_periodic_in_msh(directory="gmsh_grids"):
    """
    Finds all .msh files in the specified directory and replaces
    "periodic1" with "periodicx", "periodic2" with "periodicz",
    and "periodic3" with "periodicy" within those files.

    Args:
        directory (str, optional): The directory to search for .msh files.
                                     Defaults to "gmsh".
    """
    if not os.path.isdir(directory):
        print(f"Error: Directory '{directory}' not found.")
        return

    replacements = {
        "periodic1": "periodicx",
        "periodic2": "periodicz",
        "periodic3": "periodicy",
    }

    for filename in os.listdir(directory):
        if filename.endswith(".msh"):
            filepath = os.path.join(directory, filename)
            try:
                with open(filepath, 'r') as infile:
                    content = infile.read()

                modified_content = content
                for old, new in replacements.items():
                    modified_content = re.sub(re.escape(old), new, modified_content)

                with open(filepath, 'w') as outfile:
                    outfile.write(modified_content)

                print(f"Processed and updated: {filename}")

            except Exception as e:
                print(f"Error processing {filename}: {e}")

if __name__ == "__main__":
    replace_periodic_in_msh()
