// package com.example.my_rfid_plugin;

// import android.content.Context;
// import android.media.MediaPlayer;
// import android.os.Handler;
// import android.os.Message;
// import android.text.TextUtils;
// import android.util.Log;

// import com.rscja.barcode.BarcodeDecoder;
// import com.rscja.barcode.BarcodeFactory;
// import com.rscja.deviceapi.RFIDWithUHFUART;
// import com.rscja.deviceapi.entity.UHFTAGInfo;

// import org.json.JSONArray;
// import org.json.JSONException;
// import org.json.JSONObject;

// import java.util.ArrayList;
// import java.util.HashMap;
// import java.util.List;
// import java.util.Locale;
// import java.util.Map;
// import java.util.Objects;

// public class UHFHelper {

//     private static final String TAG = "UHFHelper";

//     private static UHFHelper instance;
//     private UHFHelper() {} // Private constructor for singleton

//     // Fields
//     private RFIDWithUHFUART mReader;
//     private BarcodeDecoder barcodeDecoder;
//     private UHFListener uhfListener;
//     private Handler handler;
//     private boolean isStart = false;
//     private boolean isConnect = false;
//     private HashMap<String, EPC> tagList;
//     private String scannedBarcode;
//     private Context context;
//     static ArrayList<String> tempTags = new ArrayList<>();

//     // Singleton accessor
//     public static UHFHelper getInstance() {
//         if (instance == null) {
//             instance = new UHFHelper();
//         }
//         return instance;
//     }

//     // Initialization
//     public void init(Context context) {
//         this.context = context;
//         tagList = new HashMap<>();
//         clearData();
//         handler = new Handler() {
//             @Override
//             public void handleMessage(Message msg) {
//                 String result = (String) msg.obj;
//                 String[] strs = result.split("@");
//                 if (strs.length == 2) {
//                     addEPCToList(strs[0], strs[1]);
//                 }
//             }
//         };
//     }

//     public boolean connect() {
//         try {
//             mReader = RFIDWithUHFUART.getInstance();
//         } catch (Exception ex) {
//             Log.e(TAG, "RFIDWithUHFUART getInstance failed", ex);
//             if (uhfListener != null) {
//                 uhfListener.onConnect(false, 0);
//             }
//             return false;
//         }
//         if (mReader != null) {
//             isConnect = mReader.init(context);
//             if (uhfListener != null) {
//                 uhfListener.onConnect(isConnect, 0);
//             }
//             return isConnect;
//         }
//         if (uhfListener != null) {
//             uhfListener.onConnect(false, 0);
//         }
//         return false;
//     }

//     public void close() {
//         isStart = false;
//         if (mReader != null) {
//             mReader.free();
//             mReader = null;
//         }
//         isConnect = false;
//         clearData();
//     }

//     // Basic status
//     public boolean isConnected() {
//         return isConnect;
//     }

//     public boolean isStarted() {
//         return isStart;
//     }

//     public boolean isEmptyTags() {
//         return (tagList == null || tagList.isEmpty());
//     }

//     // Barcode methods
//     public boolean connectBarcode() {
//         if (barcodeDecoder == null) {
//             barcodeDecoder = BarcodeFactory.getInstance().getBarcodeDecoder();
//         }
//         if (barcodeDecoder != null) {
//             barcodeDecoder.open(context);
//             return true;
//         }
//         return false;
//     }

//     public boolean scanBarcode() {
//         if (barcodeDecoder != null) {
//             barcodeDecoder.startScan();
//             return true;
//         }
//         return false;
//     }

//     public boolean stopScan() {
//         if (barcodeDecoder != null) {
//             barcodeDecoder.stopScan();
//             return true;
//         }
//         return false;
//     }

//     public boolean closeScan() {
//         if (barcodeDecoder != null) {
//             barcodeDecoder.close();
//             barcodeDecoder = null;
//         }
//         return true;
//     }

//     public String readBarcode() {
//         return (scannedBarcode != null) ? scannedBarcode : "";
//     }

//     public boolean playSound() {
//         MediaPlayer.create(context, R.raw.barcodebeep).start();
//         return true;
//     }

//     // Reader configuration
//     public boolean setPowerLevel(String level) {
//         if (mReader != null) {
//             int pwr = Integer.parseInt(level);
//             return mReader.setPower(pwr);
//         }
//         return false;
//     }

//     public boolean setWorkArea(String area) {
//         if (mReader != null) {
//             int mode = Integer.parseInt(area);
//             return mReader.setFrequencyMode(mode);
//         }
//         return false;
//     }

//     public String getPowerLevel() {
//         if (mReader != null) {
//             try {
//                 int power = mReader.getPower();
//                 return String.valueOf(power);
//             } catch (Exception e) {
//                 return "Error getPowerLevel: " + e.getMessage();
//             }
//         }
//         return "mReader is null";
//     }

//     public String getFrequencyMode() {
//         if (mReader != null) {
//             try {
//                 int freqMode = mReader.getFrequencyMode();
//                 return String.valueOf(freqMode);
//             } catch (Exception e) {
//                 return "Error getFrequencyMode: " + e.getMessage();
//             }
//         }
//         return "mReader is null";
//     }

//     public String getTemperature() {
//         if (mReader != null) {
//             try {
//                 int temp = mReader.getTemperature();
//                 return String.valueOf(temp);
//             } catch (Exception e) {
//                 return "Error getTemperature: " + e.getMessage();
//             }
//         }
//         return "mReader is null";
//     }

//     // Inventory
//     public boolean start(boolean isSingleRead) {
//         if (mReader == null) return false;
//         if (!isStart) {
//             if (isSingleRead) {
//                 UHFTAGInfo info = mReader.inventorySingleTag();
//                 if (info != null) {
//                     addEPCToList(info.getEPC(), info.getRssi());
//                     return true;
//                 } else {
//                     return false;
//                 }
//             } else {
//                 if (mReader.startInventoryTag()) {
//                     isStart = true;
//                     new TagThread().start();
//                     return true;
//                 }
//                 return false;
//             }
//         }
//         return true;
//     }

//     public boolean stop() {
//         if (isStart && mReader != null) {
//             isStart = false;
//             return mReader.stopInventory();
//         }
//         isStart = false;
//         clearData();
//         return false;
//     }

//     // Single EPC read
//     public String readSingleTagEPC() {
//         if (mReader == null) {
//             Log.e(TAG, "mReader is null, cannot readSingleTagEPC");
//             return "";
//         }
//         UHFTAGInfo info = mReader.inventorySingleTag();
//         if (info != null) {
//             String epcHex = info.getEPC();
//             Log.i(TAG, "Read single EPC: " + epcHex);
//             return epcHex;
//         }
//         return "";
//     }

//     // ADI Construct 2 Write
//     // Layout: header (8 bits) + filter (6 bits) + manager (36 bits) +
//     // part number (6-bit per char) + delimiter ("000000") +
//     // serial number (6-bit per char) + terminator ("000000")
//     public boolean writeTagADIConstruct2(String partNumber, String serialNumber) {
//         try {
//             if (mReader == null) {
//                 Log.e(TAG, "mReader is null; cannot write!");
//                 return false;
//             }

//             // Fixed fields – adjust these constants as needed
//             String headerBits = "00111011"; // 8 bits (example: 0x3B)
//             String filterBits = "001110";   // 6 bits (decimal 14)
//             String manager = " TG424";      // exactly 6 characters => 36 bits

//             // Encode each field using our 6-bit mapping
//             String managerBits = encode6Bit(manager);
//             String pnBits = encode6Bit(partNumber);
//             String snBits = encode6Bit(serialNumber);

//             // Use "000000" as both delimiter and terminator
//             String delimiter = "000000";
//             String terminator = "000000";

//             // Build the full binary string (variable length)
//             String fullBinary = headerBits + filterBits + managerBits + pnBits + delimiter + snBits + terminator;

//             // Pad to a multiple of 8 bits (if necessary)
//             int remainder = fullBinary.length() % 8;
//             if (remainder != 0) {
//                 int pad = 8 - remainder;
//                 StringBuilder padBuilder = new StringBuilder();
//                 for (int i = 0; i < pad; i++) {
//                     padBuilder.append("0");
//                 }
//                 fullBinary += padBuilder.toString();
//             }

//             // Convert binary string to hex
//             List<String> chunk8 = splitIntoChunks(fullBinary, 8);
//             String hexEPC = binaryToHex(chunk8);
//             Log.i(TAG, "Construct2 EPC to write: " + hexEPC);

//             // Write the EPC to the tag's EPC bank:
//             String accessPwd = "00000000";
//             int bank = 1;    // EPC bank
//             int ptr = 2;     // skip CRC+PC
//             int wordCount = hexEPC.length() / 4;
//             boolean success = mReader.writeData(accessPwd, bank, ptr, wordCount, hexEPC);
//             Log.e(TAG, "WriteTagADIConstruct2: success=" + success + ", errCode=" + mReader.getErrCode());

//             if (success) {
//                 MediaPlayer.create(context, R.raw.barcodebeep).start();
//             } else {
//                 MediaPlayer.create(context, R.raw.serror).start();
//             }
//             return success;
//         } catch (Exception e) {
//             Log.e(TAG, "Error writing Construct 2: " + e.getMessage(), e);
//             return false;
//         }
//     }

//     public void clearData() {
//         if (tagList != null) {
//             tagList.clear();
//         }
//     }

//     // --- 6-bit encoding using explicit mapping (matches Python mapping) ---
//     private static final Map<Character, String> CHAR_TO_6BIT;
//     static {
//         CHAR_TO_6BIT = new HashMap<>();
//         // Letters A-Z
//         CHAR_TO_6BIT.put('A', "000001");
//         CHAR_TO_6BIT.put('B', "000010");
//         CHAR_TO_6BIT.put('C', "000011");
//         CHAR_TO_6BIT.put('D', "000100");
//         CHAR_TO_6BIT.put('E', "000101");
//         CHAR_TO_6BIT.put('F', "000110");
//         CHAR_TO_6BIT.put('G', "000111");
//         CHAR_TO_6BIT.put('H', "001000");
//         CHAR_TO_6BIT.put('I', "001001");
//         CHAR_TO_6BIT.put('J', "001010");
//         CHAR_TO_6BIT.put('K', "001011");
//         CHAR_TO_6BIT.put('L', "001100");
//         CHAR_TO_6BIT.put('M', "001101");
//         CHAR_TO_6BIT.put('N', "001110");
//         CHAR_TO_6BIT.put('O', "001111");
//         CHAR_TO_6BIT.put('P', "010000");
//         CHAR_TO_6BIT.put('Q', "010001");
//         CHAR_TO_6BIT.put('R', "010010");
//         CHAR_TO_6BIT.put('S', "010011");
//         CHAR_TO_6BIT.put('T', "010100");
//         CHAR_TO_6BIT.put('U', "010101");
//         CHAR_TO_6BIT.put('V', "010110");
//         CHAR_TO_6BIT.put('W', "010111");
//         CHAR_TO_6BIT.put('X', "011000");
//         CHAR_TO_6BIT.put('Y', "011001");
//         CHAR_TO_6BIT.put('Z', "011010");
//         // Additional symbols (matching Python mapping)
//         CHAR_TO_6BIT.put('[', "011011");
//         CHAR_TO_6BIT.put('\\', "011100"); // backslash
//         CHAR_TO_6BIT.put(']', "011101");
//         CHAR_TO_6BIT.put('^', "011110");
//         CHAR_TO_6BIT.put('_', "011111");
//         // Digits
//         CHAR_TO_6BIT.put('0', "110000");
//         CHAR_TO_6BIT.put('1', "110001");
//         CHAR_TO_6BIT.put('2', "110010");
//         CHAR_TO_6BIT.put('3', "110011");
//         CHAR_TO_6BIT.put('4', "110100");
//         CHAR_TO_6BIT.put('5', "110101");
//         CHAR_TO_6BIT.put('6', "110110");
//         CHAR_TO_6BIT.put('7', "110111");
//         CHAR_TO_6BIT.put('8', "111000");
//         CHAR_TO_6BIT.put('9', "111001");
//         // Others
//         CHAR_TO_6BIT.put('?', "111111");
//         CHAR_TO_6BIT.put('!', "100001");
//         CHAR_TO_6BIT.put('#', "100011");
//         CHAR_TO_6BIT.put('$', "100100");
//         CHAR_TO_6BIT.put('%', "100101");
//         CHAR_TO_6BIT.put('&', "100110");
//         CHAR_TO_6BIT.put('\'', "100111");
//         CHAR_TO_6BIT.put('(', "101000");
//         CHAR_TO_6BIT.put(')', "101001");
//         CHAR_TO_6BIT.put('*', "101010");
//         CHAR_TO_6BIT.put('+', "101011");
//         CHAR_TO_6BIT.put(',', "101100");
//         CHAR_TO_6BIT.put('-', "101101");
//         CHAR_TO_6BIT.put('.', "101110");
//         CHAR_TO_6BIT.put('/', "101111");
//         CHAR_TO_6BIT.put(':', "111010");
//         CHAR_TO_6BIT.put(';', "111011");
//         CHAR_TO_6BIT.put('<', "111100");
//         CHAR_TO_6BIT.put('=', "111101");
//         CHAR_TO_6BIT.put('>', "111110");
//         CHAR_TO_6BIT.put(' ', "100000");
//     }

//     private String encode6Bit(String text) {
//         StringBuilder sb = new StringBuilder();
//         for (int i = 0; i < text.length(); i++) {
//             char c = text.charAt(i);
//             String bits = CHAR_TO_6BIT.get(c);
//             if (bits == null) {
//                 throw new IllegalArgumentException("Character '" + c + "' not supported in 6-bit dictionary.");
//             }
//             sb.append(bits);
//         }
//         return sb.toString();
//     }

//     // Binary -> Hex conversion
//     private List<String> splitIntoChunks(String binaryStr, int chunkSize) {
//         List<String> chunks = new ArrayList<>();
//         for (int i = 0; i < binaryStr.length(); i += chunkSize) {
//             int end = Math.min(binaryStr.length(), i + chunkSize);
//             chunks.add(binaryStr.substring(i, end));
//         }
//         return chunks;
//     }

//     private String binaryToHex(List<String> binaryChunks) {
//         StringBuilder sb = new StringBuilder();
//         for (String bin : binaryChunks) {
//             int decimal = Integer.parseInt(bin, 2);
//             String hex = Integer.toHexString(decimal).toUpperCase(Locale.ROOT);
//             if (hex.length() == 1) {
//                 sb.append('0').append(hex);
//             } else {
//                 sb.append(hex);
//             }
//         }
//         return sb.toString();
//     }

//     // Add EPC to list
//     private void addEPCToList(String epc, String rssi) {
//         if (!TextUtils.isEmpty(epc)) {
//             EPC tag = new EPC();
//             tag.setId("");
//             tag.setEpc(epc);
//             tag.setCount("1");
//             tag.setRssi(rssi);
//             if (tagList.containsKey(epc)) {
//                 int oldCount = Integer.parseInt(Objects.requireNonNull(tagList.get(epc)).getCount());
//                 tag.setCount(String.valueOf(oldCount + 1));
//             }
//             tagList.put(epc, tag);
//             JSONArray arr = new JSONArray();
//             for (EPC epcTag : tagList.values()) {
//                 JSONObject json = new JSONObject();
//                 try {
//                     json.put(TagKey.ID, epcTag.getId());
//                     json.put(TagKey.EPC, epcTag.getEpc());
//                     json.put(TagKey.RSSI, epcTag.getRssi());
//                     json.put(TagKey.COUNT, epcTag.getCount());
//                     arr.put(json);
//                 } catch (JSONException e) {
//                     e.printStackTrace();
//                 }
//             }
//             if (uhfListener != null) {
//                 uhfListener.onRead(arr.toString());
//             }
//         }
//     }

//     // Set UHFListener
//     public void setUhfListener(UHFListener uhfListener) {
//         this.uhfListener = uhfListener;
//     }

//     // Continuous inventory thread
//     class TagThread extends Thread {
//         @Override
//         public void run() {
//             while (isStart && mReader != null) {
//                 UHFTAGInfo info = mReader.readTagFromBuffer();
//                 if (info != null) {
//                     String tid = info.getTid();
//                     String epcStr = "EPC:" + info.getEPC();
//                     String rssiStr = info.getRssi();
//                     String strResult = "";
//                     if (!tid.isEmpty() && !"000000000000000000000000".equals(tid)) {
//                         strResult = "TID:" + tid + "\n";
//                     }
//                     Message msg = handler.obtainMessage();
//                     msg.obj = strResult + epcStr + "@" + rssiStr;
//                     handler.sendMessage(msg);
//                 }
//             }
//         }
//     }
// }
// package com.example.my_rfid_plugin;

// import android.content.Context;
// import android.media.MediaPlayer;
// import android.os.Handler;
// import android.os.Message;
// import android.text.TextUtils;
// import android.util.Log;

// import com.rscja.barcode.BarcodeDecoder;
// import com.rscja.barcode.BarcodeFactory;
// import com.rscja.deviceapi.RFIDWithUHFUART;
// import com.rscja.deviceapi.entity.UHFTAGInfo;

// import org.json.JSONArray;
// import org.json.JSONException;
// import org.json.JSONObject;

// import java.util.ArrayList;
// import java.util.HashMap;
// import java.util.List;
// import java.util.Locale;
// import java.util.Map;
// import java.util.Objects;

// public class UHFHelper {

//     private static final String TAG = "UHFHelper";

//     private static UHFHelper instance;
//     private UHFHelper() {} // Private constructor for singleton

//     // Fields
//     private RFIDWithUHFUART mReader;
//     private BarcodeDecoder barcodeDecoder;
//     private UHFListener uhfListener;
//     private Handler handler;
//     private boolean isStart = false;
//     private boolean isConnect = false;
//     private HashMap<String, EPC> tagList;
//     private String scannedBarcode;
//     private Context context;
//     static ArrayList<String> tempTags = new ArrayList<>();

//     // Singleton accessor
//     public static UHFHelper getInstance() {
//         if (instance == null) {
//             instance = new UHFHelper();
//         }
//         return instance;
//     }

//     // Initialization
//     public void init(Context context) {
//         this.context = context;
//         tagList = new HashMap<>();
//         clearData();
//         handler = new Handler() {
//             @Override
//             public void handleMessage(Message msg) {
//                 String result = (String) msg.obj;
//                 String[] strs = result.split("@");
//                 if (strs.length == 2) {
//                     addEPCToList(strs[0], strs[1]);
//                 }
//             }
//         };
//     }

//     public boolean connect() {
//         try {
//             mReader = RFIDWithUHFUART.getInstance();
//         } catch (Exception ex) {
//             Log.e(TAG, "RFIDWithUHFUART getInstance failed", ex);
//             if (uhfListener != null) {
//                 uhfListener.onConnect(false, 0);
//             }
//             return false;
//         }
//         if (mReader != null) {
//             isConnect = mReader.init(context);
//             if (uhfListener != null) {
//                 uhfListener.onConnect(isConnect, 0);
//             }
//             return isConnect;
//         }
//         if (uhfListener != null) {
//             uhfListener.onConnect(false, 0);
//         }
//         return false;
//     }

//     public void close() {
//         isStart = false;
//         if (mReader != null) {
//             mReader.free();
//             mReader = null;
//         }
//         isConnect = false;
//         clearData();
//     }

//     // Basic status
//     public boolean isConnected() {
//         return isConnect;
//     }

//     public boolean isStarted() {
//         return isStart;
//     }

//     public boolean isEmptyTags() {
//         return (tagList == null || tagList.isEmpty());
//     }

//     // Barcode methods
//     public boolean connectBarcode() {
//         if (barcodeDecoder == null) {
//             barcodeDecoder = BarcodeFactory.getInstance().getBarcodeDecoder();
//         }
//         if (barcodeDecoder != null) {
//             barcodeDecoder.open(context);
//             return true;
//         }
//         return false;
//     }

//     public boolean scanBarcode() {
//         if (barcodeDecoder != null) {
//             barcodeDecoder.startScan();
//             return true;
//         }
//         return false;
//     }

//     public boolean stopScan() {
//         if (barcodeDecoder != null) {
//             barcodeDecoder.stopScan();
//             return true;
//         }
//         return false;
//     }

//     public boolean closeScan() {
//         if (barcodeDecoder != null) {
//             barcodeDecoder.close();
//             barcodeDecoder = null;
//         }
//         return true;
//     }

//     public String readBarcode() {
//         return (scannedBarcode != null) ? scannedBarcode : "";
//     }

//     public boolean playSound() {
//         MediaPlayer.create(context, R.raw.barcodebeep).start();
//         return true;
//     }

//     // Reader configuration
//     public boolean setPowerLevel(String level) {
//         if (mReader != null) {
//             int pwr = Integer.parseInt(level);
//             return mReader.setPower(pwr);
//         }
//         return false;
//     }

//     public boolean setWorkArea(String area) {
//         if (mReader != null) {
//             int mode = Integer.parseInt(area);
//             return mReader.setFrequencyMode(mode);
//         }
//         return false;
//     }

//     public String getPowerLevel() {
//         if (mReader != null) {
//             try {
//                 int power = mReader.getPower();
//                 return String.valueOf(power);
//             } catch (Exception e) {
//                 return "Error getPowerLevel: " + e.getMessage();
//             }
//         }
//         return "mReader is null";
//     }

//     public String getFrequencyMode() {
//         if (mReader != null) {
//             try {
//                 int freqMode = mReader.getFrequencyMode();
//                 return String.valueOf(freqMode);
//             } catch (Exception e) {
//                 return "Error getFrequencyMode: " + e.getMessage();
//             }
//         }
//         return "mReader is null";
//     }

//     public String getTemperature() {
//         if (mReader != null) {
//             try {
//                 int temp = mReader.getTemperature();
//                 return String.valueOf(temp);
//             } catch (Exception e) {
//                 return "Error getTemperature: " + e.getMessage();
//             }
//         }
//         return "mReader is null";
//     }

//     // Inventory
//     public boolean start(boolean isSingleRead) {
//         if (mReader == null) return false;
//         if (!isStart) {
//             if (isSingleRead) {
//                 UHFTAGInfo info = mReader.inventorySingleTag();
//                 if (info != null) {
//                     addEPCToList(info.getEPC(), info.getRssi());
//                     return true;
//                 } else {
//                     return false;
//                 }
//             } else {
//                 if (mReader.startInventoryTag()) {
//                     isStart = true;
//                     new TagThread().start();
//                     return true;
//                 }
//                 return false;
//             }
//         }
//         return true;
//     }

//     public boolean stop() {
//         if (isStart && mReader != null) {
//             isStart = false;
//             return mReader.stopInventory();
//         }
//         isStart = false;
//         clearData();
//         return false;
//     }

//     // Single EPC read
//     public String readSingleTagEPC() {
//         if (mReader == null) {
//             Log.e(TAG, "mReader is null, cannot readSingleTagEPC");
//             return "";
//         }
//         UHFTAGInfo info = mReader.inventorySingleTag();
//         if (info != null) {
//             String epcHex = info.getEPC();
//             Log.i(TAG, "Read single EPC: " + epcHex);
//             return epcHex;
//         }
//         return "";
//     }

//     // ADI Construct 2 Write
//     // Layout: header (8 bits) + filter (6 bits) + manager (36 bits) +
//     // part number (6-bit per char) + delimiter ("000000") +
//     // serial number (6-bit per char) + terminator ("000000")
//     public boolean writeTagADIConstruct2(String partNumber, String serialNumber) {
//         try {
//             if (mReader == null) {
//                 Log.e(TAG, "mReader is null; cannot write!");
//                 return false;
//             }

//             // Fixed fields – adjust these constants as needed
//             String headerBits = "00111011"; // 8 bits (example: 0x3B)
//             String filterBits = "001110";   // 6 bits (decimal 14)
//             String manager = " TG424";      // exactly 6 characters => 36 bits

//             // Encode each field using our 6-bit mapping (updated mapping below)
//             String managerBits = encode6Bit(manager);
//             String pnBits = encode6Bit(partNumber);
//             String snBits = encode6Bit(serialNumber);

//             // Use "000000" as both delimiter and terminator
//             String delimiter = "000000";
//             String terminator = "000000";

//             // Build the full binary string (variable length)
//             String fullBinary = headerBits + filterBits + managerBits + pnBits + delimiter + snBits + terminator;

//             // Pad to a multiple of 8 bits (if necessary)
//             // Pad to a multiple of 16 bits (instead of 8)
//             int remainder = fullBinary.length() % 16;
//             if (remainder != 0) {
//                 int pad = 16 - remainder;
//                 StringBuilder padBuilder = new StringBuilder();
//                 for (int i = 0; i < pad; i++) {
//                     padBuilder.append("0");
//                 }
//                 fullBinary += padBuilder.toString();
//             }

//             // Convert binary string to hex
//             List<String> chunk8 = splitIntoChunks(fullBinary, 8);
//             String hexEPC = binaryToHex(chunk8);
//             Log.i(TAG, "Construct2 EPC to write: " + hexEPC);

//             // Write the EPC to the tag's EPC bank:
//             String accessPwd = "00000000";
//             int bank = 1;    // EPC bank
//             int ptr = 2;     // skip CRC+PC
//             int wordCount = hexEPC.length() / 4;
//             boolean success = mReader.writeData(accessPwd, bank, ptr, wordCount, hexEPC);
//             Log.e(TAG, "WriteTagADIConstruct2: success=" + success + ", errCode=" + mReader.getErrCode());

//             if (success) {
//                 MediaPlayer.create(context, R.raw.barcodebeep).start();
//             } else {
//                 MediaPlayer.create(context, R.raw.serror).start();
//             }
//             return success;
//         } catch (Exception e) {
//             Log.e(TAG, "Error writing Construct 2: " + e.getMessage(), e);
//             return false;
//         }
//     }

//     public void clearData() {
//         if (tagList != null) {
//             tagList.clear();
//         }
//     }

//     // --- Updated 6-bit encoding using GS1 EPC TDS 2.2 6-Bit Alphanumeric Character Set ---
//     private static final Map<Character, String> CHAR_TO_6BIT;
//     static {
//         CHAR_TO_6BIT = new HashMap<>();
//         // Allowed characters for CAGE/DODAAC encoding: space, A-Z, 0-9.
//         CHAR_TO_6BIT.put(' ', "000000");   // Space is 000000
//         CHAR_TO_6BIT.put('A', "000001");
//         CHAR_TO_6BIT.put('B', "000010");
//         CHAR_TO_6BIT.put('C', "000011");
//         CHAR_TO_6BIT.put('D', "000100");
//         CHAR_TO_6BIT.put('E', "000101");
//         CHAR_TO_6BIT.put('F', "000110");
//         CHAR_TO_6BIT.put('G', "000111");
//         CHAR_TO_6BIT.put('H', "001000");
//         CHAR_TO_6BIT.put('I', "001001");
//         CHAR_TO_6BIT.put('J', "001010");
//         CHAR_TO_6BIT.put('K', "001011");
//         CHAR_TO_6BIT.put('L', "001100");
//         CHAR_TO_6BIT.put('M', "001101");
//         CHAR_TO_6BIT.put('N', "001110");
//         CHAR_TO_6BIT.put('O', "001111");
//         CHAR_TO_6BIT.put('P', "010000");
//         CHAR_TO_6BIT.put('Q', "010001");
//         CHAR_TO_6BIT.put('R', "010010");
//         CHAR_TO_6BIT.put('S', "010011");
//         CHAR_TO_6BIT.put('T', "010100");
//         CHAR_TO_6BIT.put('U', "010101");
//         CHAR_TO_6BIT.put('V', "010110");
//         CHAR_TO_6BIT.put('W', "010111");
//         CHAR_TO_6BIT.put('X', "011000");
//         CHAR_TO_6BIT.put('Y', "011001");
//         CHAR_TO_6BIT.put('Z', "011010");
//         // Digits – assigned sequentially after letters
//         CHAR_TO_6BIT.put('0', "011011");
//         CHAR_TO_6BIT.put('1', "011100");
//         CHAR_TO_6BIT.put('2', "011101");
//         CHAR_TO_6BIT.put('3', "011110");
//         CHAR_TO_6BIT.put('4', "011111");
//         CHAR_TO_6BIT.put('5', "100000");
//         CHAR_TO_6BIT.put('6', "100001");
//         CHAR_TO_6BIT.put('7', "100010");
//         CHAR_TO_6BIT.put('8', "100011");
//         CHAR_TO_6BIT.put('9', "100100");
//         // (If additional punctuation is needed, add it here.)
//         CHAR_TO_6BIT.put('-', "101101");
//     }

//     private String encode6Bit(String text) {
//         StringBuilder sb = new StringBuilder();
//         for (int i = 0; i < text.length(); i++) {
//             char c = text.charAt(i);
//             String bits = CHAR_TO_6BIT.get(c);
//             if (bits == null) {
//                 throw new IllegalArgumentException("Character '" + c + "' not supported in 6-bit dictionary.");
//             }
//             sb.append(bits);
//         }
//         return sb.toString();
//     }

//     // Binary -> Hex conversion
//     private List<String> splitIntoChunks(String binaryStr, int chunkSize) {
//         List<String> chunks = new ArrayList<>();
//         for (int i = 0; i < binaryStr.length(); i += chunkSize) {
//             int end = Math.min(binaryStr.length(), i + chunkSize);
//             chunks.add(binaryStr.substring(i, end));
//         }
//         return chunks;
//     }

//     private String binaryToHex(List<String> binaryChunks) {
//         StringBuilder sb = new StringBuilder();
//         for (String bin : binaryChunks) {
//             int decimal = Integer.parseInt(bin, 2);
//             String hex = Integer.toHexString(decimal).toUpperCase(Locale.ROOT);
//             if (hex.length() == 1) {
//                 sb.append('0').append(hex);
//             } else {
//                 sb.append(hex);
//             }
//         }
//         return sb.toString();
//     }

//     // Add EPC to list
//     private void addEPCToList(String epc, String rssi) {
//         if (!TextUtils.isEmpty(epc)) {
//             EPC tag = new EPC();
//             tag.setId("");
//             tag.setEpc(epc);
//             tag.setCount("1");
//             tag.setRssi(rssi);
//             if (tagList.containsKey(epc)) {
//                 int oldCount = Integer.parseInt(Objects.requireNonNull(tagList.get(epc)).getCount());
//                 tag.setCount(String.valueOf(oldCount + 1));
//             }
//             tagList.put(epc, tag);
//             JSONArray arr = new JSONArray();
//             for (EPC epcTag : tagList.values()) {
//                 JSONObject json = new JSONObject();
//                 try {
//                     json.put(TagKey.ID, epcTag.getId());
//                     json.put(TagKey.EPC, epcTag.getEpc());
//                     json.put(TagKey.RSSI, epcTag.getRssi());
//                     json.put(TagKey.COUNT, epcTag.getCount());
//                     arr.put(json);
//                 } catch (JSONException e) {
//                     e.printStackTrace();
//                 }
//             }
//             if (uhfListener != null) {
//                 uhfListener.onRead(arr.toString());
//             }
//         }
//     }

//     // Set UHFListener
//     public void setUhfListener(UHFListener uhfListener) {
//         this.uhfListener = uhfListener;
//     }

//     // Continuous inventory thread
//     class TagThread extends Thread {
//         @Override
//         public void run() {
//             while (isStart && mReader != null) {
//                 UHFTAGInfo info = mReader.readTagFromBuffer();
//                 if (info != null) {
//                     String tid = info.getTid();
//                     String epcStr = "EPC:" + info.getEPC();
//                     String rssiStr = info.getRssi();
//                     String strResult = "";
//                     if (!tid.isEmpty() && !"000000000000000000000000".equals(tid)) {
//                         strResult = "TID:" + tid + "\n";
//                     }
//                     Message msg = handler.obtainMessage();
//                     msg.obj = strResult + epcStr + "@" + rssiStr;
//                     handler.sendMessage(msg);
//                 }
//             }
//         }
//     }
// }

// package com.example.my_rfid_plugin;

// import android.content.Context;
// import android.media.MediaPlayer;
// import android.os.Handler;
// import android.os.Message;
// import android.text.TextUtils;
// import android.util.Log;

// import com.rscja.barcode.BarcodeDecoder;
// import com.rscja.barcode.BarcodeFactory;
// import com.rscja.deviceapi.RFIDWithUHFUART;
// import com.rscja.deviceapi.entity.UHFTAGInfo;

// import org.json.JSONArray;
// import org.json.JSONException;
// import org.json.JSONObject;

// import java.util.ArrayList;
// import java.util.HashMap;
// import java.util.List;
// import java.util.Locale;
// import java.util.Map;
// import java.util.Objects;

/**
 * UHFHelper
 *
 * A helper Singleton class for reading/writing RFID tags using the
 * RFIDWithUHFUART device API.
 */
// public class UHFHelper {

//     private static final String TAG = "UHFHelper";

//     private static UHFHelper instance;
//     private UHFHelper() {} // Private constructor for singleton

//     // Fields
//     private RFIDWithUHFUART mReader;
//     private BarcodeDecoder barcodeDecoder;
//     private UHFListener uhfListener;
//     private Handler handler;
//     private boolean isStart = false;
//     private boolean isConnect = false;
//     private HashMap<String, EPC> tagList;
//     private String scannedBarcode;
//     private Context context;
//     static ArrayList<String> tempTags = new ArrayList<>();

//     // Singleton accessor
//     public static UHFHelper getInstance() {
//         if (instance == null) {
//             instance = new UHFHelper();
//         }
//         return instance;
//     }

//     // Initialization
//     public void init(Context context) {
//         this.context = context;
//         tagList = new HashMap<>();
//         clearData();
//         handler = new Handler() {
//             @Override
//             public void handleMessage(Message msg) {
//                 String result = (String) msg.obj;
//                 String[] strs = result.split("@");
//                 if (strs.length == 2) {
//                     addEPCToList(strs[0], strs[1]);
//                 }
//             }
//         };
//     }

//     public boolean connect() {
//         try {
//             mReader = RFIDWithUHFUART.getInstance();
//         } catch (Exception ex) {
//             Log.e(TAG, "RFIDWithUHFUART getInstance failed", ex);
//             if (uhfListener != null) {
//                 uhfListener.onConnect(false, 0);
//             }
//             return false;
//         }
//         if (mReader != null) {
//             isConnect = mReader.init(context);
//             if (uhfListener != null) {
//                 uhfListener.onConnect(isConnect, 0);
//             }
//             return isConnect;
//         }
//         if (uhfListener != null) {
//             uhfListener.onConnect(false, 0);
//         }
//         return false;
//     }

//     public void close() {
//         isStart = false;
//         if (mReader != null) {
//             mReader.free();
//             mReader = null;
//         }
//         isConnect = false;
//         clearData();
//     }

//     // Basic status
//     public boolean isConnected() {
//         return isConnect;
//     }

//     public boolean isStarted() {
//         return isStart;
//     }

//     public boolean isEmptyTags() {
//         return (tagList == null || tagList.isEmpty());
//     }

//     // Barcode methods
//     public boolean connectBarcode() {
//         if (barcodeDecoder == null) {
//             barcodeDecoder = BarcodeFactory.getInstance().getBarcodeDecoder();
//         }
//         if (barcodeDecoder != null) {
//             barcodeDecoder.open(context);
//             return true;
//         }
//         return false;
//     }

//     public boolean scanBarcode() {
//         if (barcodeDecoder != null) {
//             barcodeDecoder.startScan();
//             return true;
//         }
//         return false;
//     }

//     public boolean stopScan() {
//         if (barcodeDecoder != null) {
//             barcodeDecoder.stopScan();
//             return true;
//         }
//         return false;
//     }

//     public boolean closeScan() {
//         if (barcodeDecoder != null) {
//             barcodeDecoder.close();
//             barcodeDecoder = null;
//         }
//         return true;
//     }

//     public String readBarcode() {
//         return (scannedBarcode != null) ? scannedBarcode : "";
//     }

//     public boolean playSound() {
//         MediaPlayer.create(context, R.raw.barcodebeep).start();
//         return true;
//     }

//     // Reader configuration
//     public boolean setPowerLevel(String level) {
//         if (mReader != null) {
//             int pwr = Integer.parseInt(level);
//             return mReader.setPower(pwr);
//         }
//         return false;
//     }

//     public boolean setWorkArea(String area) {
//         if (mReader != null) {
//             int mode = Integer.parseInt(area);
//             return mReader.setFrequencyMode(mode);
//         }
//         return false;
//     }

//     public String getPowerLevel() {
//         if (mReader != null) {
//             try {
//                 int power = mReader.getPower();
//                 return String.valueOf(power);
//             } catch (Exception e) {
//                 return "Error getPowerLevel: " + e.getMessage();
//             }
//         }
//         return "mReader is null";
//     }

//     public String getFrequencyMode() {
//         if (mReader != null) {
//             try {
//                 int freqMode = mReader.getFrequencyMode();
//                 return String.valueOf(freqMode);
//             } catch (Exception e) {
//                 return "Error getFrequencyMode: " + e.getMessage();
//             }
//         }
//         return "mReader is null";
//     }

//     public String getTemperature() {
//         if (mReader != null) {
//             try {
//                 int temp = mReader.getTemperature();
//                 return String.valueOf(temp);
//             } catch (Exception e) {
//                 return "Error getTemperature: " + e.getMessage();
//             }
//         }
//         return "mReader is null";
//     }

//     // Inventory
//     public boolean start(boolean isSingleRead) {
//         if (mReader == null) return false;
//         if (!isStart) {
//             if (isSingleRead) {
//                 UHFTAGInfo info = mReader.inventorySingleTag();
//                 if (info != null) {
//                     addEPCToList(info.getEPC(), info.getRssi());
//                     return true;
//                 } else {
//                     return false;
//                 }
//             } else {
//                 if (mReader.startInventoryTag()) {
//                     isStart = true;
//                     new TagThread().start();
//                     return true;
//                 }
//                 return false;
//             }
//         }
//         return true;
//     }

//     public boolean stop() {
//         if (isStart && mReader != null) {
//             isStart = false;
//             return mReader.stopInventory();
//         }
//         isStart = false;
//         clearData();
//         return false;
//     }

//     // Single EPC read
//     public String readSingleTagEPC() {
//         if (mReader == null) {
//             Log.e(TAG, "mReader is null, cannot readSingleTagEPC");
//             return "";
//         }
//         UHFTAGInfo info = mReader.inventorySingleTag();
//         if (info != null) {
//             String epcHex = info.getEPC();
//             Log.i(TAG, "Read single EPC: " + epcHex);
//             return epcHex;
//         }
//         return "";
//     }

//     //-------------------------------------------------------------------------
//     // ADI Construct 2 Write (UPDATED to handle "long" EPC + PC Bits)
//     //-------------------------------------------------------------------------

//     /**
//      * Layout for ADI Construct 2: header(8 bits) + filter(6 bits) + manager(36 bits) +
//      * partNumber(6-bit/char) + delimiter("000000") + serialNumber(6-bit/char) + terminator("000000")
//      * This method now also updates the PC Bits so the entire EPC is reported, if it's longer than 96 bits.
//      */
//     public boolean writeTagADIConstruct2(String partNumber, String serialNumber) {
//         try {
//             if (mReader == null) {
//                 Log.e(TAG, "mReader is null; cannot write!");
//                 return false;
//             }

//             // 1) Build ADI Construct 2 bits (existing logic)
//             String headerBits = "00111011";  // example: 0x3B
//             String filterBits = "001110";    // 6 bits => decimal 14
//             String manager = " TG424";       // exactly 6 chars => 36 bits

//             // Convert to 6-bit per char
//             String managerBits = encode6Bit(manager);
//             String pnBits = encode6Bit(partNumber);
//             String snBits = encode6Bit(serialNumber);

//             // "000000" as delimiter & terminator
//             String delimiter = "000000";
//             String terminator = "000000";

//             // Build full binary
//             String fullBinary = headerBits + filterBits + managerBits + pnBits + delimiter + snBits + terminator;

//             // Pad to multiple of 16 bits
//             int remainder = fullBinary.length() % 16;
//             if (remainder != 0) {
//                 int pad = 16 - remainder;
//                 StringBuilder padBuilder = new StringBuilder();
//                 for (int i = 0; i < pad; i++) {
//                     padBuilder.append("0");
//                 }
//                 fullBinary += padBuilder.toString();
//             }

//             // Convert to hex
//             List<String> chunk8 = splitIntoChunks(fullBinary, 8);
//             String hexEPC = binaryToHex(chunk8);
//             Log.i(TAG, "Construct2 EPC (Hex) = " + hexEPC);

//             // 2) Write this EPC to the tag's EPC memory bank
//             String accessPwd = "00000000";
//             int bank = 1;        // EPC bank
//             int ptrEpc = 2;      // skip CRC + PC
//             int wordCountEpc = hexEPC.length() / 4;  // each word = 16 bits = 4 hex chars

//             boolean successEpc = mReader.writeData(accessPwd, bank, ptrEpc, wordCountEpc, hexEPC);
//             if (!successEpc) {
//                 Log.e(TAG, "Write EPC data failed, errCode=" + mReader.getErrCode());
//                 MediaPlayer.create(context, R.raw.serror).start();
//                 return false;
//             }

//             // 3) Now read the existing PC Bits (word offset=1) so we can update the EPC length field
//             String oldPcHex = mReader.readData(accessPwd, bank, 1, 1); // read 1 word
//             if (oldPcHex == null) {
//                 Log.e(TAG, "Failed reading old PC bits - cannot update length properly!");
//                 // not mandatory to fail the entire operation, but let's do so for correctness:
//                 MediaPlayer.create(context, R.raw.serror).start();
//                 return false;
//             }

//             int oldPcBits = Integer.parseInt(oldPcHex, 16);
//             int newPcBits = setEpcLength(oldPcBits, wordCountEpc);
//             if (newPcBits != oldPcBits) {
//                 String newPcHex = String.format(Locale.US, "%04X", newPcBits);
//                 boolean successPc = mReader.writeData(accessPwd, bank, 1, 1, newPcHex);
//                 if (!successPc) {
//                     Log.e(TAG, "Write PC Bits failed, errCode=" + mReader.getErrCode());
//                     MediaPlayer.create(context, R.raw.serror).start();
//                     return false;
//                 }
//             }

//             // 4) Success beep if all good
//             MediaPlayer.create(context, R.raw.barcodebeep).start();
//             return true;

//         } catch (Exception e) {
//             Log.e(TAG, "Error writing Construct 2: " + e.getMessage(), e);
//             return false;
//         }
//     }

//     /**
//      * Updates the lower 5 bits of 'oldPcBits' to indicate the new EPC length, in words.
//      * This ensures that if the new EPC is longer than the default 96 bits, the reader
//      * will backscatter the entire length in inventory.
//      */
//     private int setEpcLength(int oldPcBits, int lengthWords) {
//         // 31 words (496 bits) is the max for a 5-bit field
//         if (lengthWords < 0 || lengthWords > 31) {
//             throw new IllegalArgumentException("EPC length must be between 0 and 31 words.");
//         }
//         // Clear the lower 5 bits
//         int cleared = oldPcBits & 0xFFE0; 
//         // OR in the new length
//         int updated = cleared | (lengthWords & 0x1F);
//         return updated;
//     }

//     // Clears the HashMap
//     public void clearData() {
//         if (tagList != null) {
//             tagList.clear();
//         }
//     }

//     //-------------------------------------------------------------------------
//     // 6-bit encoding dictionary for ADI
//     //-------------------------------------------------------------------------
//     private static final Map<Character, String> CHAR_TO_6BIT;
//     static {
//         CHAR_TO_6BIT = new HashMap<>();
//         // Allowed characters: SPACE, A-Z, 0-9, plus we add '-' as example
//         CHAR_TO_6BIT.put(' ', "000000");
//         CHAR_TO_6BIT.put('A', "000001");
//         CHAR_TO_6BIT.put('B', "000010");
//         CHAR_TO_6BIT.put('C', "000011");
//         CHAR_TO_6BIT.put('D', "000100");
//         CHAR_TO_6BIT.put('E', "000101");
//         CHAR_TO_6BIT.put('F', "000110");
//         CHAR_TO_6BIT.put('G', "000111");
//         CHAR_TO_6BIT.put('H', "001000");
//         CHAR_TO_6BIT.put('I', "001001");
//         CHAR_TO_6BIT.put('J', "001010");
//         CHAR_TO_6BIT.put('K', "001011");
//         CHAR_TO_6BIT.put('L', "001100");
//         CHAR_TO_6BIT.put('M', "001101");
//         CHAR_TO_6BIT.put('N', "001110");
//         CHAR_TO_6BIT.put('O', "001111");
//         CHAR_TO_6BIT.put('P', "010000");
//         CHAR_TO_6BIT.put('Q', "010001");
//         CHAR_TO_6BIT.put('R', "010010");
//         CHAR_TO_6BIT.put('S', "010011");
//         CHAR_TO_6BIT.put('T', "010100");
//         CHAR_TO_6BIT.put('U', "010101");
//         CHAR_TO_6BIT.put('V', "010110");
//         CHAR_TO_6BIT.put('W', "010111");
//         CHAR_TO_6BIT.put('X', "011000");
//         CHAR_TO_6BIT.put('Y', "011001");
//         CHAR_TO_6BIT.put('Z', "011010");
//         // Digits
//         CHAR_TO_6BIT.put('0', "011011");
//         CHAR_TO_6BIT.put('1', "011100");
//         CHAR_TO_6BIT.put('2', "011101");
//         CHAR_TO_6BIT.put('3', "011110");
//         CHAR_TO_6BIT.put('4', "011111");
//         CHAR_TO_6BIT.put('5', "100000");
//         CHAR_TO_6BIT.put('6', "100001");
//         CHAR_TO_6BIT.put('7', "100010");
//         CHAR_TO_6BIT.put('8', "100011");
//         CHAR_TO_6BIT.put('9', "100100");
//         // Example punctuation
//         CHAR_TO_6BIT.put('-', "101101");
//     }

//     /**
//      * Encodes a string into your 6-bit dictionary. 
//      * Throws an exception if an unsupported char is encountered.
//      */
//     private String encode6Bit(String text) {
//         StringBuilder sb = new StringBuilder();
//         for (int i = 0; i < text.length(); i++) {
//             char c = text.charAt(i);
//             String bits = CHAR_TO_6BIT.get(c);
//             if (bits == null) {
//                 throw new IllegalArgumentException("Character '" + c + "' not supported in 6-bit dictionary.");
//             }
//             sb.append(bits);
//         }
//         return sb.toString();
//     }

//     //-------------------------------------------------------------------------
//     // Binary -> Hex conversion helpers
//     //-------------------------------------------------------------------------
//     private List<String> splitIntoChunks(String binaryStr, int chunkSize) {
//         List<String> chunks = new ArrayList<>();
//         for (int i = 0; i < binaryStr.length(); i += chunkSize) {
//             int end = Math.min(binaryStr.length(), i + chunkSize);
//             chunks.add(binaryStr.substring(i, end));
//         }
//         return chunks;
//     }

//     private String binaryToHex(List<String> binaryChunks) {
//         StringBuilder sb = new StringBuilder();
//         for (String bin : binaryChunks) {
//             int decimal = Integer.parseInt(bin, 2);
//             String hex = Integer.toHexString(decimal).toUpperCase(Locale.ROOT);
//             if (hex.length() == 1) {
//                 sb.append('0').append(hex);
//             } else {
//                 sb.append(hex);
//             }
//         }
//         return sb.toString();
//     }

//     //-------------------------------------------------------------------------
//     // Add EPC to list + JSON array
//     //-------------------------------------------------------------------------
//     private void addEPCToList(String epc, String rssi) {
//         if (!TextUtils.isEmpty(epc)) {
//             EPC tag = new EPC();
//             tag.setId("");
//             tag.setEpc(epc);
//             tag.setCount("1");
//             tag.setRssi(rssi);
//             if (tagList.containsKey(epc)) {
//                 int oldCount = Integer.parseInt(Objects.requireNonNull(tagList.get(epc)).getCount());
//                 tag.setCount(String.valueOf(oldCount + 1));
//             }
//             tagList.put(epc, tag);

//             // Build JSON
//             JSONArray arr = new JSONArray();
//             for (EPC epcTag : tagList.values()) {
//                 JSONObject json = new JSONObject();
//                 try {
//                     json.put(TagKey.ID, epcTag.getId());
//                     json.put(TagKey.EPC, epcTag.getEpc());
//                     json.put(TagKey.RSSI, epcTag.getRssi());
//                     json.put(TagKey.COUNT, epcTag.getCount());
//                     arr.put(json);
//                 } catch (JSONException e) {
//                     e.printStackTrace();
//                 }
//             }

//             if (uhfListener != null) {
//                 uhfListener.onRead(arr.toString());
//             }
//         }
//     }

//     //-------------------------------------------------------------------------
//     // Set UHFListener
//     //-------------------------------------------------------------------------
//     public void setUhfListener(UHFListener uhfListener) {
//         this.uhfListener = uhfListener;
//     }

//     //-------------------------------------------------------------------------
//     // Continuous inventory thread
//     //-------------------------------------------------------------------------
//     class TagThread extends Thread {
//         @Override
//         public void run() {
//             while (isStart && mReader != null) {
//                 UHFTAGInfo info = mReader.readTagFromBuffer();
//                 if (info != null) {
//                     String tid = info.getTid();
//                     String epcStr = "EPC:" + info.getEPC();
//                     String rssiStr = info.getRssi();
//                     String strResult = "";
//                     if (!tid.isEmpty() && !"000000000000000000000000".equals(tid)) {
//                         strResult = "TID:" + tid + "\n";
//                     }
//                     Message msg = handler.obtainMessage();
//                     msg.obj = strResult + epcStr + "@" + rssiStr;
//                     handler.sendMessage(msg);
//                 }
//             }
//         }
//     }
// }

package com.example.my_rfid_plugin;

import android.content.Context;
import android.media.MediaPlayer;
import android.os.Handler;
import android.os.Message;
import android.text.TextUtils;
import android.util.Log;
import io.flutter.plugin.common.EventChannel;

import com.rscja.barcode.BarcodeDecoder;
import com.rscja.barcode.BarcodeFactory;
import com.rscja.deviceapi.RFIDWithUHFUART;
import com.rscja.deviceapi.entity.UHFTAGInfo;
import com.rscja.deviceapi.interfaces.IUHFLocationCallback;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

public class UHFHelper {

    private static final String TAG = "UHFHelper";

    private static UHFHelper instance;

    private UHFHelper() {
    } // Singleton

    // Fields
    private RFIDWithUHFUART mReader;
    private BarcodeDecoder barcodeDecoder;
    private UHFListener uhfListener;
    private Handler handler;
    private boolean isStart = false;
    private boolean isConnect = false;
    private HashMap<String, EPC> tagList;
    private String scannedBarcode;
    private Context context;
    private static EventChannel.EventSink locationSink;
    static ArrayList<String> tempTags = new ArrayList<>();
    private String currentRecordType = "DRT";
    private int currentEpcWords = 12;
    private int currentUserWords = 32;
    private int currentPermalockWords = 0;

    // Singleton accessor
    public static UHFHelper getInstance() {
        if (instance == null) {
            instance = new UHFHelper();
        }
        return instance;
    }

    // Initialization
    public void init(Context context) {
        this.context = context;
        tagList = new HashMap<>();
        clearData();
        handler = new Handler() {
            @Override
            public void handleMessage(Message msg) {
                String result = (String) msg.obj;
                String[] strs = result.split("@");
                if (strs.length == 2) {
                    addEPCToList(strs[0], strs[1]);
                }
            }
        };
    }

    public boolean connect() {
        try {
            mReader = RFIDWithUHFUART.getInstance();
        } catch (Exception ex) {
            Log.e(TAG, "RFIDWithUHFUART getInstance failed", ex);
            if (uhfListener != null) {
                uhfListener.onConnect(false, 0);
            }
            return false;
        }
        if (mReader != null) {
            isConnect = mReader.init(context);
            if (uhfListener != null) {
                uhfListener.onConnect(isConnect, 0);
            }
            return isConnect;
        }
        if (uhfListener != null) {
            uhfListener.onConnect(false, 0);
        }
        if (isConnect) {
            try { mReader.setEPCMode(); } catch (Exception ignore) {}
            try { mReader.setTagFocus(true); } catch (Exception ignore) {}
            try { mReader.setFastID(true); } catch (Exception ignore) {}
        }
        return false;
    }

    public void close() {
        isStart = false;
        if (mReader != null) {
            mReader.free();
            mReader = null;
        }
        isConnect = false;
        clearData();
    }

    // Basic status
    public boolean isConnected() {
        return isConnect;
    }

    public boolean isStarted() {
        return isStart;
    }

    public boolean isEmptyTags() {
        return (tagList == null || tagList.isEmpty());
    }

    // Barcode methods
    public boolean connectBarcode() {
        if (barcodeDecoder == null) {
            barcodeDecoder = BarcodeFactory.getInstance().getBarcodeDecoder();
        }
        if (barcodeDecoder != null) {
            barcodeDecoder.open(context);
            return true;
        }
        return false;
    }

    public boolean scanBarcode() {
        if (barcodeDecoder != null) {
            barcodeDecoder.startScan();
            return true;
        }
        return false;
    }

    public boolean stopScan() {
        if (barcodeDecoder != null) {
            barcodeDecoder.stopScan();
            return true;
        }
        return false;
    }

    public boolean closeScan() {
        if (barcodeDecoder != null) {
            barcodeDecoder.close();
            barcodeDecoder = null;
        }
        return true;
    }

    public String readBarcode() {
        return (scannedBarcode != null) ? scannedBarcode : "";
    }

    public boolean playSound() {
        MediaPlayer.create(context, R.raw.barcodebeep).start();
        return true;
    }

    // Reader configuration
    public boolean setPowerLevel(String level) {
        if (mReader != null) {
            int pwr = Integer.parseInt(level);
            return mReader.setPower(pwr);
        }
        return false;
    }

    public boolean setWorkArea(String area) {
        if (mReader != null) {
            int mode = Integer.parseInt(area);
            return mReader.setFrequencyMode(mode);
        }
        return false;
    }

    public void clearData() {
        if (tagList != null) {
            tagList.clear();
        }
    }

    public String getPowerLevel() {
        if (mReader != null) {
            try {
                int power = mReader.getPower();
                return String.valueOf(power);
            } catch (Exception e) {
                return "Error getPowerLevel: " + e.getMessage();
            }
        }
        return "mReader is null";
    }

    public String getFrequencyMode() {
        if (mReader != null) {
            try {
                int freqMode = mReader.getFrequencyMode();
                return String.valueOf(freqMode);
            } catch (Exception e) {
                return "Error getFrequencyMode: " + e.getMessage();
            }
        }
        return "mReader is null";
    }

    public String getTemperature() {
        if (mReader != null) {
            try {
                int temp = mReader.getTemperature();
                return String.valueOf(temp);
            } catch (Exception e) {
                return "Error getTemperature: " + e.getMessage();
            }
        }
        return "mReader is null";
    }

    // Inventory
    public boolean start(boolean isSingleRead) {
        if (mReader == null)
            return false;
        if (!isStart) {
            if (isSingleRead) {
                UHFTAGInfo info = mReader.inventorySingleTag();
                if (info != null) {
                    addEPCToList(info.getEPC(), info.getRssi());
                    return true;
                } else {
                    return false;
                }
            } else {
                if (mReader.startInventoryTag()) {
                    isStart = true;
                    new TagThread().start();
                    return true;
                }
                return false;
            }
        }
        return true;
    }

    public boolean stop() {
        if (isStart && mReader != null) {
            isStart = false;
            return mReader.stopInventory();
        }
        isStart = false;
        clearData();
        return false;
    }

    // Single EPC read
    public String readSingleTagEPC() {
        if (mReader == null) {
            Log.e(TAG, "mReader is null, cannot readSingleTagEPC");
            return "";
        }
        UHFTAGInfo info = mReader.inventorySingleTag();
        if (info != null) {
            String epcHex = info.getEPC();
            Log.i(TAG, "Read single EPC: " + epcHex);
            return epcHex;
        }
        return "";
    }

    // ----------- ASIL EPC YAZMA KODU (ATA/GS1/6bit ve PC Word ile) -----------
    public boolean writeTagADIConstruct2(String partNumber, String serialNumber) {
        try {
            if (mReader == null) {
                Log.e(TAG, "mReader is null; cannot write!");
                return false;
            }

            // Header, filter ve CAGE/manager kodu
            String headerBits = "00111011"; // 8 bit header
            String filterBits = "001110"; // 6 bit filter
            String manager = " TG424"; // 6 karakter CAGE kodu

            StringBuilder epcBin = new StringBuilder();
            epcBin.append(headerBits);
            epcBin.append(filterBits);
            epcBin.append(encode6Bit(manager));

            // Parça numarası (PN)
            epcBin.append(encode6Bit(partNumber));
            epcBin.append("000000"); // Delimiter

            // Seri numarası (SN)
            epcBin.append(encode6Bit(serialNumber));
            epcBin.append("000000"); // Delimiter

            // 16 bit'e tamamlamak için padding
            // int padBits = (16 - (epcBin.length() % 16)) % 16;
            // for (int i = 0; i < padBits; i++)
            // epcBin.append('0');
            int padBits = (8 - (epcBin.length() % 8)) % 8;
            for (int i = 0; i < padBits; i++)
                epcBin.append('0');

            // Binary -> Hex
            StringBuilder epcHex = new StringBuilder();
            for (int i = 0; i < epcBin.length(); i += 4) {
                String chunk = epcBin.substring(i, i + 4);
                epcHex.append(Integer.toHexString(Integer.parseInt(chunk, 2)).toUpperCase(Locale.ROOT));
            }

            // Word & PC Word hesaplama
            int epcBitLen = epcBin.length();
            int epcWordCount = epcBitLen / 16;
            int pcWord = (epcWordCount << 11) | 0x3000;
            String pcWordHex = String.format("%04X", pcWord);

            Log.i(TAG, "Construct2 EPC to write (with PC): PC=" + pcWordHex + " EPC=" + epcHex);

            // PC+EPC toplam data (ilk word PC, devamı EPC data)
            String writeData = pcWordHex + epcHex.toString();

            String accessPwd = "00000000";
            int bank = 1; // EPC bank
            int ptr = 1; // PC word adresi
            int wordCount = epcWordCount + 1; // PC+EPC toplam word

            boolean success = mReader.writeData(accessPwd, bank, ptr, wordCount, writeData);
            Log.e(TAG, "WriteTagADIConstruct2: success=" + success + ", errCode=" + mReader.getErrCode());

            if (success) {
                MediaPlayer.create(context, R.raw.barcodebeep).start();
            } else {
                MediaPlayer.create(context, R.raw.serror).start();
            }
            return success;
        } catch (Exception e) {
            Log.e(TAG, "Error writing Construct 2: " + e.getMessage(), e);
            return false;
        }
    }

    // public boolean programConstruct2Epc(String partNumber, String serialNumber,
    // String manager6, String accessPwdHex) {
    // if (mReader == null)
    // return false;
    // try {
    // String headerBits = "00111011"; // 8b header
    // // Filter’ı şimdilik 14 bırakabilirsiniz; isterseniz UI’den seçtireceğiz
    // String filterBits = String.format("%6s",
    // Integer.toBinaryString(14)).replace(' ', '0');

    // StringBuilder epcBits = new StringBuilder();
    // epcBits.append(headerBits).append(filterBits)
    // .append(encode6Bit(manager6))
    // .append(encode6Bit(partNumber)).append("000000")
    // .append(encode6Bit(serialNumber)).append("000000");

    // // yalnız nibble hizası
    // // int pad4 = (4 - (epcBits.length() % 4)) % 4;
    // // for (int i = 0; i < pad4; i++)
    // // epcBits.append('0');
    // // 16-bit (1 word) hizası: SDK writeDataToEpc HEX uzunluğunu 4’ün katı ister
    // int pad16 = (16 - (epcBits.length() % 16)) % 16;
    // for (int i = 0; i < pad16; i++)
    // epcBits.append('0');

    // // bin->hex (her 4 bit → 1 hex)
    // StringBuilder epcHex = new StringBuilder();
    // for (int i = 0; i < epcBits.length(); i += 4) {
    // epcHex.append(Integer.toHexString(
    // Integer.parseInt(epcBits.substring(i, i + 4), 2)).toUpperCase(Locale.ROOT));
    // }
    // // emniyet: HEX mutlaka 4’ün katı olmalı
    // if ((epcHex.length() & 0x3) != 0) {
    // // son nibble’ı 0 ile büyüt (teorik olarak pad16 bunu engeller ama garanti
    // // edelim)
    // int need = 4 - (epcHex.length() & 0x3);
    // for (int i = 0; i < need; i++)
    // epcHex.append('0');
    // }

    // // bin->hex
    // StringBuilder epcHex = new StringBuilder();
    // for (int i = 0; i < epcBits.length(); i += 4) {
    // epcHex.append(
    // Integer.toHexString(Integer.parseInt(epcBits.substring(i, i + 4),
    // 2)).toUpperCase(Locale.ROOT));
    // }

    // String pwd = (accessPwdHex == null || accessPwdHex.isEmpty()) ? "00000000" :
    // accessPwdHex;
    // // ÖNEMLİ: PC word’ü biz hesaplamıyoruz; SDK yapıyor → extra 0 biter
    // return mReader.writeDataToEpc(pwd, epcHex.toString());
    // } catch (Exception e) {
    // Log.e(TAG, "programConstruct2Epc", e);
    // return false;
    // }
    // }
    public boolean programConstruct2Epc(String partNumber, String serialNumber,
            String manager6, String accessPwdHex, int filterValue) {
        if (mReader == null)
            return false;
        try {
            String headerBits = "00111011"; // ADI header
            int fv = (filterValue < 0 || filterValue > 63) ? 0 : filterValue;
            String filterBits = String.format("%6s", Integer.toBinaryString(fv)).replace(' ', '0');

            StringBuilder epcBits = new StringBuilder();
            epcBits.append(headerBits).append(filterBits)
                    .append(encode6Bit(manager6))
                    .append(encode6Bit(partNumber)).append("000000")
                    .append(encode6Bit(serialNumber)).append("000000");

            // 16-bit (word) hizası – writeDataToEpc HEX uzunluğu 4’ün katı olmalı
            int pad16 = (16 - (epcBits.length() % 16)) % 16;
            for (int i = 0; i < pad16; i++)
                epcBits.append('0');

            // bin -> hex (4 bit -> 1 hex)
            StringBuilder epcHex = new StringBuilder();
            for (int i = 0; i < epcBits.length(); i += 4) {
                epcHex.append(Integer.toHexString(
                        Integer.parseInt(epcBits.substring(i, i + 4), 2)).toUpperCase(Locale.ROOT));
            }
            // emniyet: 4’ün katı değilse tamamla (pad16 zaten engeller; yine de garanti)
            while ((epcHex.length() & 0x3) != 0)
                epcHex.append('0');

            String pwd = (accessPwdHex == null || accessPwdHex.isEmpty()) ? "00000000" : accessPwdHex;
            return mReader.writeDataToEpc(pwd, epcHex.toString()); // PC auto-adapt
        } catch (Exception e) {
            Log.e(TAG, "programConstruct2Epc(filter)", e);
            return false;
        }
    }

    public boolean prepareAtaChip(String recordType,
            int epcWords,
            int userWords,
            int permalockWords,
            boolean enablePermalock,
            boolean lockEpc,
            boolean lockUser,
            String accessPwdHex) {
        if (mReader == null) {
            Log.e(TAG, "prepareAtaChip: mReader is null");
            return false;
        }
        try {
            // if inventory is running, pausing can prevent write/read clashes
            boolean wasRunning = isStart;
            if (wasRunning) {
                mReader.stopInventory();
                isStart = false;
            }

            // just cache the values; we will use them when building USER header
            currentRecordType = (recordType == null ? "DRT" : recordType);
            currentEpcWords = Math.max(8, epcWords);
            currentUserWords = Math.max(0, userWords);
            currentPermalockWords = Math.max(0, permalockWords);

            // TODO: If SDK has lock/block-permalock APIs, call them here using
            // enablePermalock/lockEpc/lockUser/accessPwdHex.

            // (optional) resume inventory if it was running
            // if (wasRunning) { mReader.startInventoryTag(); isStart = true; new
            // TagThread().start(); }

            return true;
        } catch (Exception e) {
            Log.e(TAG, "prepareAtaChip failed", e);
            return false;
        }
    }

    // -------------------- 6-bit GS1 EPC Kod Tablosu ----------------------
    private static final Map<Character, String> CHAR_TO_6BIT;
    static {
        CHAR_TO_6BIT = new HashMap<>();
        CHAR_TO_6BIT.put(' ', "100000"); // SPACE
        CHAR_TO_6BIT.put('A', "000001");
        CHAR_TO_6BIT.put('B', "000010");
        CHAR_TO_6BIT.put('C', "000011");
        CHAR_TO_6BIT.put('D', "000100");
        CHAR_TO_6BIT.put('E', "000101");
        CHAR_TO_6BIT.put('F', "000110");
        CHAR_TO_6BIT.put('G', "000111");
        CHAR_TO_6BIT.put('H', "001000");
        CHAR_TO_6BIT.put('I', "001001");
        CHAR_TO_6BIT.put('J', "001010");
        CHAR_TO_6BIT.put('K', "001011");
        CHAR_TO_6BIT.put('L', "001100");
        CHAR_TO_6BIT.put('M', "001101");
        CHAR_TO_6BIT.put('N', "001110");
        CHAR_TO_6BIT.put('O', "001111");
        CHAR_TO_6BIT.put('P', "010000");
        CHAR_TO_6BIT.put('Q', "010001");
        CHAR_TO_6BIT.put('R', "010010");
        CHAR_TO_6BIT.put('S', "010011");
        CHAR_TO_6BIT.put('T', "010100");
        CHAR_TO_6BIT.put('U', "010101");
        CHAR_TO_6BIT.put('V', "010110");
        CHAR_TO_6BIT.put('W', "010111");
        CHAR_TO_6BIT.put('X', "011000");
        CHAR_TO_6BIT.put('Y', "011001");
        CHAR_TO_6BIT.put('Z', "011010");
        CHAR_TO_6BIT.put('[', "011011");
        CHAR_TO_6BIT.put('\\', "011100");
        CHAR_TO_6BIT.put(']', "011101");
        CHAR_TO_6BIT.put('^', "011110");
        CHAR_TO_6BIT.put('_', "011111");
        CHAR_TO_6BIT.put('0', "110000");
        CHAR_TO_6BIT.put('1', "110001");
        CHAR_TO_6BIT.put('2', "110010");
        CHAR_TO_6BIT.put('3', "110011");
        CHAR_TO_6BIT.put('4', "110100");
        CHAR_TO_6BIT.put('5', "110101");
        CHAR_TO_6BIT.put('6', "110110");
        CHAR_TO_6BIT.put('7', "110111");
        CHAR_TO_6BIT.put('8', "111000");
        CHAR_TO_6BIT.put('9', "111001");
        CHAR_TO_6BIT.put('?', "111111");
        CHAR_TO_6BIT.put('!', "100001");
        CHAR_TO_6BIT.put('#', "100011");
        CHAR_TO_6BIT.put('$', "100100");
        CHAR_TO_6BIT.put('%', "100101");
        CHAR_TO_6BIT.put('&', "100110");
        CHAR_TO_6BIT.put('\'', "100111");
        CHAR_TO_6BIT.put('(', "101000");
        CHAR_TO_6BIT.put(')', "101001");
        CHAR_TO_6BIT.put('*', "101010");
        CHAR_TO_6BIT.put('+', "101011");
        CHAR_TO_6BIT.put(',', "101100");
        CHAR_TO_6BIT.put('-', "101101");
        CHAR_TO_6BIT.put('.', "101110");
        CHAR_TO_6BIT.put('/', "101111");
        CHAR_TO_6BIT.put(':', "111010");
        CHAR_TO_6BIT.put(';', "111011");
        CHAR_TO_6BIT.put('<', "111100");
        CHAR_TO_6BIT.put('=', "111101");
        CHAR_TO_6BIT.put('>', "111110");
    }

    private static final Map<String, Character> SIXBIT_TO_CHAR;
    static {
        SIXBIT_TO_CHAR = new HashMap<>();
        for (Map.Entry<Character, String> e : CHAR_TO_6BIT.entrySet()) {
            SIXBIT_TO_CHAR.put(e.getValue(), e.getKey());
        }
    }

    // USER (header+payload) HEX -> sadece payload metni (6-bit decode)
    private String decodeUserPayloadHexToText(String userHex) {
        if (userHex == null || userHex.length() < 16)
            return "";
        // w0..w3 (16 hex) header'ı at, kalan payload
        String payloadHex = userHex.substring(16);

        // hex -> bit dizisi
        StringBuilder bits = new StringBuilder(payloadHex.length() * 4);
        for (int i = 0; i < payloadHex.length(); i++) {
            int v = Integer.parseInt(payloadHex.substring(i, i + 1), 16);
            bits.append(String.format("%4s", Integer.toBinaryString(v)).replace(' ', '0'));
        }

        // 6'şar bit çöz; "000000" (end delimiter) gelince dur
        StringBuilder out = new StringBuilder();
        for (int i = 0; i + 6 <= bits.length(); i += 6) {
            String sextet = bits.substring(i, i + 6);
            if ("000000".equals(sextet))
                break;
            Character ch = SIXBIT_TO_CHAR.get(sextet);
            out.append(ch != null ? ch : '?');
        }
        return out.toString();
    }

    // "*MFR XXX*PNR YYY*SER ZZZ*DMF 20240601*PDT ..." metninden alanları ayıkla
    private Map<String, String> parseAtaUserText(String text) {
        Map<String, String> res = new HashMap<>();
        if (text == null || text.isEmpty())
            return res;

        String[] parts = text.split("\\*");
        for (String part : parts) {
            part = part.trim();
            if (part.isEmpty())
                continue;
            int sp = part.indexOf(' ');
            if (sp <= 0)
                continue;
            String key = part.substring(0, sp).trim(); // MFR/PNR/SER/DMF/PDT/UIC...
            String val = part.substring(sp + 1).trim();
            res.put(key, val);
        }
        return res;
    }

    private String encode6Bit(String text) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            String bits = CHAR_TO_6BIT.get(c);
            if (bits == null) {
                throw new IllegalArgumentException("Character '" + c + "' not supported in 6-bit dictionary.");
            }
            sb.append(bits);
        }
        return sb.toString();
    }

    // [ADD] Map UI recordType -> ATA Short ToC 'Tag Type' field
    private int mapAtaTagType(String rt) {
        if (rt == null)
            return 2; // default: Single Record Tag (SRT)
        String r = rt.toUpperCase(Locale.ROOT);
        if (r.startsWith("DRT"))
            return 3; // Dual Record Tag
        if (r.startsWith("MRT"))
            return 4; // Multiple Record Tag
        // SRT (Birth/Utility) -> 2
        return 2;
    }

    // Binary -> Hex conversion (her 4 bit için 1 hex karakter)
    private List<String> splitIntoChunks(String binaryStr, int chunkSize) {
        List<String> chunks = new ArrayList<>();
        for (int i = 0; i < binaryStr.length(); i += chunkSize) {
            int end = Math.min(binaryStr.length(), i + chunkSize);
            chunks.add(binaryStr.substring(i, end));
        }
        return chunks;
    }

    // Belirli EPC için USER alanlarını oku, decode et ve JSON döndür
    public String readUserFieldsForEpc(String epcHex) {
        try {
            String userHex = readUserMemoryForEpc(epcHex); // sende zaten var
            if (userHex == null || userHex.isEmpty())
                return "{}";

            String text = decodeUserPayloadHexToText(userHex);
            Map<String, String> fields = parseAtaUserText(text);

            JSONObject obj = new JSONObject();
            obj.put("rawHex", userHex);
            obj.put("rawText", text);
            obj.put("MFR", fields.getOrDefault("MFR", ""));
            obj.put("PDT", fields.getOrDefault("PDT", ""));
            obj.put("PNR", fields.getOrDefault("PNR", ""));
            obj.put("SER", fields.getOrDefault("SER", ""));
            obj.put("DMF", fields.getOrDefault("DMF", ""));
            obj.put("UIC", fields.getOrDefault("UIC", ""));
            return obj.toString();
        } catch (Exception e) {
            Log.e(TAG, "readUserFieldsForEpc", e);
            return "{}";
        }
    }

    // Şu an RAM'de tuttuğumuz taranmış tag listesi (EPC/RSSI/COUNT) -> JSON array
    public String getCurrentTagsJson() {
        try {
            JSONArray arr = new JSONArray();
            if (tagList != null) {
                for (EPC t : tagList.values()) {
                    JSONObject j = new JSONObject();
                    j.put("id", t.getId());
                    j.put("epc", t.getEpc());
                    j.put("rssi", t.getRssi());
                    j.put("count", t.getCount());
                    arr.put(j);
                }
            }
            return arr.toString();
        } catch (Exception e) {
            Log.e(TAG, "getCurrentTagsJson", e);
            return "[]";
        }
    }

    private String binaryToHex(List<String> binaryChunks) {
        StringBuilder sb = new StringBuilder();
        for (String bin : binaryChunks) {
            int decimal = Integer.parseInt(bin, 2);
            String hex = Integer.toHexString(decimal).toUpperCase(Locale.ROOT);
            if (hex.length() == 1) {
                sb.append('0').append(hex);
            } else {
                sb.append(hex);
            }
        }
        return sb.toString();
    }

    // Add EPC to list
    private void addEPCToList(String epc, String rssi) {
        if (!TextUtils.isEmpty(epc)) {
            EPC tag = new EPC();
            tag.setId("");
            tag.setEpc(epc);
            tag.setCount("1");
            tag.setRssi(rssi);
            if (tagList.containsKey(epc)) {
                int oldCount = Integer.parseInt(Objects.requireNonNull(tagList.get(epc)).getCount());
                tag.setCount(String.valueOf(oldCount + 1));
            }
            tagList.put(epc, tag);
            JSONArray arr = new JSONArray();
            for (EPC epcTag : tagList.values()) {
                JSONObject json = new JSONObject();
                try {
                    json.put(TagKey.ID, epcTag.getId());
                    json.put(TagKey.EPC, epcTag.getEpc());
                    json.put(TagKey.RSSI, epcTag.getRssi());
                    json.put(TagKey.COUNT, epcTag.getCount());
                    arr.put(json);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            if (uhfListener != null) {
                uhfListener.onRead(arr.toString());
            }
        }
    }

    // Set UHFListener
    public void setUhfListener(UHFListener uhfListener) {
        this.uhfListener = uhfListener;
    }

    // Continuous inventory thread
    class TagThread extends Thread {
        @Override
        public void run() {
            while (isStart && mReader != null) {
                UHFTAGInfo info = mReader.readTagFromBuffer();
                if (info != null) {
                    String tid = info.getTid();
                    String epcStr = "EPC:" + info.getEPC();
                    String rssiStr = info.getRssi();
                    String strResult = "";
                    if (!tid.isEmpty() && !"000000000000000000000000".equals(tid)) {
                        strResult = "TID:" + tid + "\n";
                    }
                    Message msg = handler.obtainMessage();
                    msg.obj = strResult + epcStr + "@" + rssiStr;
                    handler.sendMessage(msg);
                }
            }
        }
    }

    public boolean writeAtaUserMemoryWithPayload(
            String manufacturer, String productName, String partNumber,
            String serialNumber, String manufactureDate) {
        if (mReader == null) {
            Log.e(TAG, "mReader is null; cannot write User Memory header!");
            return false;
        }
        try {
            // --- 1. Build ATA Spec payload string (with field names per spec) ---
            StringBuilder payloadBuilder = new StringBuilder();
            if (manufacturer != null && !manufacturer.isEmpty())
                payloadBuilder.append("*MFR ").append(manufacturer);
            if (productName != null && !productName.isEmpty())
                payloadBuilder.append("*PDT ").append(productName);
            if (partNumber != null && !partNumber.isEmpty())
                payloadBuilder.append("*PNR ").append(partNumber);
            if (serialNumber != null && !serialNumber.isEmpty())
                payloadBuilder.append("*SER ").append(serialNumber);
            if (manufactureDate != null && !manufactureDate.isEmpty())
                payloadBuilder.append("*DMF ").append(manufactureDate);
            payloadBuilder.append("*UIC 2");

            // Remove leading "*" if present (optional)
            String ataPayloadText = (payloadBuilder.length() > 0 && payloadBuilder.charAt(0) == '*')
                    ? payloadBuilder.substring(1)
                    : payloadBuilder.toString();

            // --- 2. Encode to 6-bit GS1/ATA Spec ---
            StringBuilder payload6bit = new StringBuilder();
            for (char c : ataPayloadText.toCharArray()) {
                String sixBits = CHAR_TO_6BIT.get(Character.toUpperCase(c));
                if (sixBits == null) {
                    Log.w(TAG, "Unsupported char in user memory: " + c);
                    sixBits = "000000"; // Substitute NUL
                }
                payload6bit.append(sixBits);
            }
            payload6bit.append("000000"); // End delimiter

            // --- 3. Pad payload to nearest 16 bits ---
            int padBits = (16 - (payload6bit.length() % 16)) % 16;
            for (int i = 0; i < padBits; i++)
                payload6bit.append('0');
            int payloadWords = payload6bit.length() / 16;

            // --- 4. Build Short ToC header ---
            int dsfid = 0x1E00; // Fixed
            int tocMajor = 6; // Usually 6
            int tocMinor = 1; // Usually 1
            int ataClass = 1; // 1 for flyable
            int tagType = mapAtaTagType(currentRecordType); // 2 for Single Birth-Record
            int flags = 0; // All bits 0
            int tocHeaderSize = 4;
            int tocRdSize = 0;
            int userMemWords = 4 + payloadWords; // header + payload

            // Header words
            String w0 = String.format("%04X", dsfid);
            int word1 = ((tocMinor & 0x7) << 13)
                    | ((tocMajor & 0xF) << 9)
                    | ((tagType & 0xF) << 5)
                    | (ataClass & 0x1F);

            String w1 = String.format("%04X", word1);
            int word2 = ((flags & 0xFF) << 8)
                    | ((tocHeaderSize & 0xF) << 4)
                    | (tocRdSize & 0xF);
            String w2 = String.format("%04X", word2);
            String w3 = String.format("%04X", userMemWords);

            // --- 5. Encode 6-bit binary to hex (4 bits per hex digit) ---
            StringBuilder payloadHex = new StringBuilder();
            String bits = payload6bit.toString();
            for (int i = 0; i < bits.length(); i += 4) {
                String chunk = bits.substring(i, Math.min(i + 4, bits.length()));
                payloadHex.append(Integer.toHexString(Integer.parseInt(chunk, 2)).toUpperCase(Locale.ROOT));
            }

            // --- 6. Combine header and payload hex
            String userMemHex = w0 + w1 + w2 + w3 + payloadHex.toString();
            Log.i(TAG, "User Memory (Short ToC): " + userMemHex);

            // --- 7. Write to USER memory bank ---
            String accessPwd = "00000000";
            int bank = 3; // USER memory
            int ptr = 0; // Start at word 0
            int wordCount = userMemWords; // header + payload words

            boolean success = mReader.writeData(accessPwd, bank, ptr, wordCount, userMemHex);
            Log.i(TAG, "Write Short ToC User Memory result: " + (success ? "SUCCESS" : "FAILED"));

            return success;

        } catch (Exception e) {
            Log.e(TAG, "Error writing User Memory Short ToC+payload: " + e.getMessage(), e);
            return false;
        }
    }

    // Reads USER memory of the tag
    // public String readUserMemory() {
    // if (mReader == null) {
    // Log.e(TAG, "mReader is null; cannot read USER memory!");
    // return "";
    // }
    // try {
    // String accessPwd = "00000000"; // Access password
    // int bank = 3; // USER memory
    // int ptr = 0; // start at word 0
    // int wordCount = 32; // Read 32 words

    // String userHex = mReader.readData(
    // accessPwd, bank, ptr, wordCount);
    // Log.i(TAG, "Read USER memory : " + userHex);
    // return userHex != null ? userHex : "";
    // } catch (Exception e) {
    // Log.e(TAG, "Error reading USER memory for EPC: " + e.getMessage(), e);
    // return "";
    // }
    // }
    public String readUserMemory() {
        if (mReader == null) {
            Log.e(TAG, "mReader is null; cannot read USER memory!");
            return "";
        }
        boolean resumeInventory = false;
        try {
            // envanter çalışıyorsa durdur
            if (isStart) {
                resumeInventory = true;
                mReader.stopInventory();
            }
            String accessPwd = "00000000";
            // Header (w0..w3)
            String hdr = mReader.readData(accessPwd, RFIDWithUHFUART.Bank_USER, 0, 4);
            if (hdr == null || hdr.length() < 16) {
                Log.e(TAG, "USER header read failed");
                return "";
            }
            int w3 = Integer.parseInt(hdr.substring(12, 16), 16);
            if (w3 < 4)
                w3 = 4;
            String all = mReader.readData(accessPwd, RFIDWithUHFUART.Bank_USER, 0, w3);
            Log.i(TAG, "Read USER memory exact: " + all);
            return all != null ? all : "";
        } catch (Exception e) {
            Log.e(TAG, "Error reading USER memory exact", e);
            return "";
        } finally {
            // gerekirse envanteri yeniden başlat
            if (resumeInventory) {
                try {
                    mReader.startInventoryTag();
                    isStart = true;
                    new TagThread().start();
                } catch (Exception ignore) {
                }
            }
        }
    }

    public boolean setEpcFilterForHex(String epcHex) {
        if (mReader == null)
            return false;
        try {
            int bits = epcHex != null ? epcHex.length() * 4 : 0;
            if (bits <= 0)
                return false;
            return mReader.setFilter(RFIDWithUHFUART.Bank_EPC, 32, bits, epcHex);
        } catch (Exception e) {
            Log.e(TAG, "setEpcFilterForHex", e);
            return false;
        }
    }

    public boolean clearFilter() {
        if (mReader == null)
            return false;
        try {
            return mReader.setFilter(RFIDWithUHFUART.Bank_EPC, 0, 0, "");
        } catch (Exception e) {
            Log.e(TAG, "clearFilter", e);
            return false;
        }
    }

    public String readUserMemoryForEpc(String epcHex) {
        if (mReader == null)
            return "";
        boolean wasRunning = isStart;
        try {
            // Envanter açıksa durdur (çarpışma/65535 hata riskini azaltır)
            if (wasRunning) {
                mReader.stopInventory();
                isStart = false;
            }

            String accessPwd = "00000000";
            int filterBank = RFIDWithUHFUART.Bank_EPC;
            int filterPtrBits = 32; // PC word’ü atla; EPC bitleri 32’den başlar
            int filterCntBits = epcHex.length() * 4; // HEX → bit

            // 1) Header (w0..w3) – kısa okuma
            String hdr = mReader.readData(
                    accessPwd,
                    filterBank, filterPtrBits, filterCntBits, epcHex, // filtre
                    RFIDWithUHFUART.Bank_USER, 0, 4 // hedef: USER w0..w3
            );
            if (hdr == null || hdr.length() < 16)
                return "";

            int w3 = Integer.parseInt(hdr.substring(12, 16), 16);
            if (w3 < 4)
                w3 = 4;

            // 2) Tam uzunluk USER okuma
            return mReader.readData(
                    accessPwd,
                    filterBank, filterPtrBits, filterCntBits, epcHex, // filtre
                    RFIDWithUHFUART.Bank_USER, 0, w3);
        } catch (Exception e) {
            Log.e(TAG, "readUserMemoryForEpc(filtered)", e);
            return "";
        } finally {
            // Envanteri eski haline getir
            if (wasRunning) {
                try {
                    mReader.startInventoryTag();
                    isStart = true;
                    new TagThread().start();
                } catch (Exception ignored) {
                }
            }
        }
    }

    public static void setLocationSink(EventChannel.EventSink sink) {
        locationSink = sink;
    }

    private int lastPowerLevel = 5;

    public boolean startLocation(Context context, String label, int bank, int ptr) {
        if (mReader == null) {
            Log.e(TAG, "mReader is null; cannot start location!");
            return false;
        }
        try {
            lastPowerLevel = mReader.getPower();

            mReader.setPower(30);
            return mReader.startLocation(this.context, label, bank, ptr, new IUHFLocationCallback() {
                @Override
                public void getLocationValue(int value) {
                    Log.i(TAG, "Location signal strength: " + value);
                    if (locationSink != null)
                        locationSink.success(value); // <-- KRİTİK
                }
            });
        } catch (Exception e) {
            Log.e(TAG, "Error starting location: " + e.getMessage(), e);
            return false;
        }
    }

    public boolean stopLocation() {
        if (mReader == null) {
            Log.e(TAG, "mReader is null; cannot stop location!");
            return false;
        }
        try {
            mReader.setPower(lastPowerLevel);

            return mReader.stopLocation();
        } catch (Exception e) {
            Log.e(TAG, "Error stopping location: " + e.getMessage(), e);
            return false;
        }
    }

    public interface TagLocateListener {
        void onLocateValue(int value);
    }

    private TagLocateListener tagLocateListener;

    public void setTagLocateListener(TagLocateListener listener) {
        this.tagLocateListener = listener;
    }

}
