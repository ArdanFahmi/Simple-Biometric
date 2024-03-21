import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import com.example.simple_biometric.MainActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.util.concurrent.Executor
import android.util.Log
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import android.util.Base64
import java.io.*
import javax.crypto.spec.IvParameterSpec

class BiometricHandler(private val context: Context) {

    private val executor: Executor = ContextCompat.getMainExecutor(context)
    private val biometricPrompt: BiometricPrompt

    init {
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                //channel.invokeMethod("authenticationFailed", null)
            }

            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                //channel.invokeMethod("authenticationSucceeded", null)
                val cryptoObject = result.cryptoObject
                val cipher = cryptoObject?.cipher
                if (cipher != null) {
                    try {

                        val cipher = initCipher() // Initialize your Cipher object
                        val serializedParameters = serializeCipherParameters(cipher)
                        println("Serialized Cipher Parameters: $serializedParameters")

                        val rawByteArray = "Your raw byte array data".toByteArray()
                        val processedByteArray = cipher.doFinal(rawByteArray)

                        /*
                        val keyGenerator =
                            KeyGenerator.getInstance(
                                KeyProperties.KEY_ALGORITHM_AES,
                                "AndroidKeyStore"
                            )
                        val keyStore = KeyStore.getInstance("AndroidKeyStore")
                        keyStore.load(null)
                        keyGenerator.init(
                            KeyGenParameterSpec.Builder(
                                "my_key_alias", // Replace with your preferred key alias
                                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
                            )
                                .setBlockModes(KeyProperties.BLOCK_MODE_CBC) // Set block mode as per your requirements
                                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_PKCS7) // Set padding as per your requirements
                                .setRandomizedEncryptionRequired(false) // Set this according to your requirements
                                .build()
                        )
                        val secretKey = keyGenerator.generateKey()
                        val iv = ByteArray(decryptionCipher.blockSize)
                        SecureRandom().nextBytes(iv)

                        val decryptionCipher =
                            Cipher.getInstance("${KeyProperties.KEY_ALGORITHM_AES}/${KeyProperties.BLOCK_MODE_CBC}/${KeyProperties.ENCRYPTION_PADDING_PKCS7}")
                        val ivParameterSpec = IvParameterSpec(iv)
                        decryptionCipher.init(
                            Cipher.DECRYPT_MODE,
                            secretKey,
                            ivParameterSpec
                        ) // Use the same secretKey as used for encryption

                        // Decrypt the processedByteArray
                        val decryptedByteArray = decryptionCipher.doFinal(processedByteArray)
                         */

                        Log.d("onAuthenticationSucceeded", processedByteArray.toString())
                    } catch (e: Exception) {
                        Log.e("TAG", "Error encrypting data: ${e.message}")
                    }
                } else {
                    Log.e("TAG", "Cipher is null")
                }
            }

            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
            }
        }

        biometricPrompt = BiometricPrompt(context as MainActivity, executor, callback)
    }

    fun authenticate() {
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric Authentication")
            .setSubtitle("Authenticate using your biometric data")
            .setNegativeButtonText("Cancel")
            .build()

        biometricPrompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(initCipher()))
    }

    fun initCipher(): Cipher {
        // Generate a key for encryption/decryption
        val keyGenerator =
            KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        keyGenerator.init(
            KeyGenParameterSpec.Builder(
                "my_key_alias", // Replace with your preferred key alias
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_CBC) // Set block mode as per your requirements
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_PKCS7) // Set padding as per your requirements
                .setRandomizedEncryptionRequired(false) // Set this according to your requirements
                .build()
        )
        val secretKey = keyGenerator.generateKey()

        // Initialize the cipher
        val cipher =
            Cipher.getInstance("${KeyProperties.KEY_ALGORITHM_AES}/${KeyProperties.BLOCK_MODE_CBC}/${KeyProperties.ENCRYPTION_PADDING_PKCS7}")
        cipher.init(
            Cipher.ENCRYPT_MODE,
            secretKey
        ) // Change mode to DECRYPT_MODE if using for decryption
        return cipher
    }

    fun serializeCipherParameters(cipher: Cipher): String {
        // Extract necessary parameters from the Cipher object
        val algorithm = cipher.algorithm
        val mode = cipher.algorithm
        val iv = cipher.parameters.getParameterSpec(IvParameterSpec::class.java).iv

        // Create a string representation of the parameters
        val serializedParameters = "$algorithm:$mode:${Base64.encodeToString(iv, Base64.DEFAULT)}"
        return serializedParameters
    }

    // Deserialize a Cipher object from a serialized string
    fun deserializeCipher(serializedParameters: String): Cipher {
        val keyGenerator =
            KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        keyGenerator.init(
            KeyGenParameterSpec.Builder(
                "my_key_alias", // Replace with your preferred key alias
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_CBC) // Set block mode as per your requirements
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_PKCS7) // Set padding as per your requirements
                .setRandomizedEncryptionRequired(false) // Set this according to your requirements
                .build()
        )
        val secretKey = keyGenerator.generateKey()
        
        // Parse the serialized string to extract the parameters
        val parts = serializedParameters.split(":")
        val algorithm = parts[0]
        val mode = parts[1]
        val padding = parts[2]
        val iv = Base64.decode(parts[3], Base64.DEFAULT)

        // Reconstruct the Cipher object with the extracted parameters
        val cipher = Cipher.getInstance("$algorithm/$mode/$padding")
        val ivParameterSpec = IvParameterSpec(iv)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, ivParameterSpec) // Use appropriate key
        return cipher
    }

}

