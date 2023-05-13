#include <cstdio>
#include <cstring>

extern "C" {
/*
JNIEXPORT jstring JNICALL Java_info_setmy_jni_example_Example_getHelloString
  (JNIEnv *env, jobject obj, jstring javaString) {

    jclass cls = (*env).GetObjectClass(obj);
    //http://dev.kanngard.net/Permalinks/ID_20050509144235.html
    jmethodID mid = (*env).GetMethodID(cls, "fromJNI", "(Ljava/lang/String;)Ljava/lang/String;");
    if (mid == 0) {
        printf("CPP code: Java Method NOT found!\n");
        return javaString;
    } else {
        printf("CPP code: Java Method IS found!\n");
    }

    const char *str;
    str = env->GetStringUTFChars(javaString, NULL);
    if (str == NULL) {
        return NULL;
    }
    printf("CPP code: %s\n", str);
    (*env).ReleaseStringUTFChars(javaString, str);

    char buf[512];
    memset(buf, 0, sizeof (buf));
    jobject resultObj = (*env).CallObjectMethod(obj, mid, javaString);
    str = (*env).GetStringUTFChars((jstring) resultObj, NULL);//str = (*env).GetStringUTFChars(javaString, NULL);
    if (str == NULL) {
        printf("CPP code: str is NULL\n");
    } else {
        printf("CPP code before: str is \"%s\"\n", str);
        strncpy(buf, str, sizeof (buf));
        printf("CPP code after: str is \"%s\"\n", buf);
        (*env).ReleaseStringUTFChars(javaString, str);
        jstring ret = (*env).NewStringUTF(buf);
        return ret;
    }
    return javaString;
}*/
}
