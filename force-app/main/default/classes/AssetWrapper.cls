public class AssetWrapper {

	public class MeasuringPoint {
		public String measPoint;
		public String counterReading;
		public String mpUnit;
	}

	public class NoteText {
		public String tagColumn;
		public String textLine;
	}
    
    public class InformationText {
		public String textLine;
	}

	public class VehicleTextData {
		public InformationText informationText;
		public List<NoteText> noteText;
	}

	public String vin;
	public String vehicleNum;
	public String vehicleRegNum;
	public String regNumCountryKey;
	public String oemVin;
	public String manufacturer;
	public String prodCode;
	public String modelRange;
	public String vehicleType;
	public String typeVariant;
	public String deliveryExWorkDate;
	public String firstRegDate;
	public String wheelBase;
	public String overhang;
	public String suspension;
	public String truckAxle;
	public String customerRegDate;
	public String customerNo;
	public String customerName;
	public MeasuringPoint measuringPoint;
	public VehicleTextData vehicleTextData;

	
	public static AssetWrapper parse(String json) {
		return (AssetWrapper) System.JSON.deserialize(json, AssetWrapper.class);
	}
}