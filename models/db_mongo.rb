class RoomAllocation
	include Mongoid::Document
	field :hotelid, type: String
	field :roomno, type: String
	field :date, type: Date
	field :type, type: String
	field :resno, type: String
	field :ressno, type: Integer
	field :rsdsno, type: String
	field :name, type: String
	field :pkgcode, type: String
	field :tariff, type: Float
	field :intime, type: String
	field :outtime, type: String
	field :status, type: String
	field :shortname, type: String
	field :fxd, type: String

	index(
		[
			[ :hotelid, Mongo::ASCENDING],
			[ :roomno, Mongo::ASCENDING],
			[ :date, Mongo::ASCENDING]
		],
		unique: true
	)

	def to_csv
		[
			hotelid, roomno, date, type, resno, ressno, 
			rsdsno, name, pkgcode, tariff, intime,
			outtime,status,shortname
		].to_csv
	end
end