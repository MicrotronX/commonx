unit DTNetConst;

interface
const
  MAX_PACKET_SIZE = 80000;
  PACKET_MARKER = $119B92A8;
  PACKET_ADDRESS_MARKER : nativeint = 0;
  PACKET_ADDRESS_CRC : nativeint = 4;
  PACKET_ADDRESS_PACKED_LENGTH : nativeint = 8;
  PACKET_ADDRESS_UNPACKED_LENGTH : nativeint = 16;
  PACKET_ADDRESS_TYPE : nativeint = 24;
  PACKET_ADDRESS_ENCRYPTION : nativeint = 25;

  PACKET_ADDRESS_USERDATA : nativeint = 26;

  PACKET_HEADER_SIZE : nativeint = 26;

  //Packet Data Types
  PDT_SHORT     = 1;        PDT_LENGTH_SHORT = 2;
  PDT_LONG      = 2;        PDT_LENGTH_LONG = 4;
  PDT_STRING    = 3;
  PDT_BYTES     = 4;
  PDT_DOUBLE    = 5;        PDT_LENGTH_DOUBLE = 8;
  PDT_DATETIME      = 6;    PDT_LENGTH_DATETIME = 8;
  PDT_SHORT_OBJECT  = 7;    PDT_LENGTH_SHORT_OBJECT = 7;
  PDT_LONG_OBJECT   = 8;    PDT_LENGTH_LONG_OBJECT = 12;
  PDT_LONG_LONG     = 9;    PDT_LENGTH_LONG_LONG = 8;
  PDT_BOOLEAN       = 10;   PDT_LENGTH_BOOLEAN = 1;
  PDT_NULL          = 11;   PDT_LENGTH_NULL = 0;
  PDT_EOF          = 12;    PDT_LENGTH_EOF = 0;
  PDT_NOTEOF       = 13;    PDT_LENGTH_NOTEOF = 0;

const
  KEY_SESSION = '100';


  //Server Requests
  RQ_NONE     = 1     ; RSP_NONE = 1;
  RQ_STATUS   = 2     ; RSP_STATUS  = 2    ;



  RQ_GET_OBJECT = 101 ; RSP_GET_OBJECT = 101;
  RQ_PUT_OBJECT = 102 ; RSP_PUT_OBJECT = 102;
  RQ_NEW_OBJECT = 103 ; RSP_NEW_OBJECT = 103;
  RQ_DEL_OBJECT = 104 ; RSP_DEL_OBJECT = 104;

  RQ_LOGIN    = $1001 ; RSP_LOGIN   = $1001;
  RQ_LOGOUT   = $1002 ; RSP_LOGOUT  = $1002;
  RQ_VERIFY_ACCOUNT = $100A; RSP_VERIFY_ACCOUNT = $100A;

  PACKET_TYPE_PROGRESS = 69;
  PACKET_TYPE_CALLBACK = 70;
  PACKET_TYPE_CALLBACK_RESPONSE = 71;  

  //Protocol Level
  //Incrment this if a new revision of the protocol is present
  SERVER_PROTOCOL_LEVEL = 4;

  WINSOCK_TIMEOUT = 60;

  //Enctyption types
  ENC_NONE = 0;
  ENC_SIMPLE = 1;
  ENC_USER = 2;

  //Data object types
  DO_USER = 1;
  DO_ACTIVITY = 2;


  //Data object styles
  DO_STYLE_LEARNER_FULL = 0;
  DO_STYLE_LEARNER_BRIEF = 1;
  DO_STYLE_ADMIN_BREIF = 2;
  DO_STYLE_FULL = 3;

implementation


end.


