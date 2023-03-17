import sys
import base64

if __name__ == "__main__":
    try:
        print(str(base64.b64encode(sys.argv[1].encode("utf-8")), "utf-8"))
    except IndexError as index_error:
        print("Provide single string for encryption")
