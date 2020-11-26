#include <stdlib.h>
#include <jni.h>
#include <time.h>

static const char *const messages[] = {
  "Hello, world!",
  "Hej världen!",
  "Bonjour, monde!",
  "Hallo Welt!"
};

JNIEXPORT jstring JNICALL Java_com_vkand_MainActivity_getMessage
  (JNIEnv *env, jobject obj)
{
int i;
  srand(time(NULL));
  i = rand() % (sizeof(messages) / sizeof(messages[0]));
  return (*env)->NewStringUTF(env, messages[i]);
}