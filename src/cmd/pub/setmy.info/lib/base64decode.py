import sys
import base64

if __name__ == "__main__":
    try:
        print(str(base64.b64decode(sys.argv[1]), "utf-8"))
    except IndexError as index_error:
        print("Provide single string for decoding")
