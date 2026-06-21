class JobModel {
  String id, jobType, companyName, plate, category, brand, model, modelYear, deviceModel, imei, cameraImei, simNo, technician, notes, signature, accessories, deliveredTo, receiverName;
  bool isCompleted;
  DateTime date;

  JobModel({
    required this.id,
    required this.jobType,
    required this.companyName,
    this.plate = '',
    this.category = '',
    this.brand = '',
    this.model = '',
    this.modelYear = '',
    this.deviceModel = '',
    this.imei = '',
    this.cameraImei = '',
    this.simNo = '',
    this.technician = '',
    this.notes = '',
    this.signature = '',
    this.accessories = '',
    this.deliveredTo = '',
    this.receiverName = '',
    this.isCompleted = false,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'jobType': jobType,
    'companyName': companyName,
    'plate': plate,
    'category': category,
    'brand': brand,
    'model': model,
    'modelYear': modelYear,
    'deviceModel': deviceModel,
    'imei': imei,
    'cameraImei': cameraImei,
    'simNo': simNo,
    'technician': technician,
    'notes': notes,
    'signature': signature,
    'accessories': accessories,
    'deliveredTo': deliveredTo,
    'receiverName': receiverName,
    'isCompleted': isCompleted ? 1 : 0,
    'date': date.toIso8601String(),
  };

  factory JobModel.fromMap(Map<String, dynamic> map) => JobModel(
    id: map['id'] ?? '',
    jobType: map['jobType'] ?? '',
    companyName: map['companyName'] ?? '',
    plate: map['plate'] ?? '',
    category: map['category'] ?? '',
    brand: map['brand'] ?? '',
    model: map['model'] ?? '',
    modelYear: map['modelYear'] ?? '',
    deviceModel: map['deviceModel'] ?? '',
    imei: map['imei'] ?? '',
    cameraImei: map['cameraImei'] ?? '',
    simNo: map['simNo'] ?? '',
    technician: map['technician'] ?? '',
    notes: map['notes'] ?? '',
    signature: map['signature'] ?? '',
    accessories: map['accessories'] ?? '',
    deliveredTo: map['deliveredTo'] ?? '',
    receiverName: map['receiverName'] ?? '',
    isCompleted: map['isCompleted'] == 1,
    date: DateTime.parse(map['date']),
  );
}
