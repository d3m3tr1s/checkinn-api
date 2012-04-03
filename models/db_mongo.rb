class Access
	include Mongoid::Document
	field :key, type: String
	field :secret, type: String
	field :hotelid, type: String
	field :root, type: Boolean

	index :key, unique: true
end	

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
			outtime, status, shortname, fxd
		].to_csv
	end
end

class Booking
	include Mongoid::Document

	field :hotelid, type: String	
	field :no, type: String
	field :bkg_sno, type: String
	field :rsd_sno, type: String
	field :atnd_by, type: String
	field :bkd_by, type: String
	field :roomno, type: String
	field :enq_no, type: String
	field :add, type: String
	field :city, type: String
	field :pin, type: String
	field :cont_no, type: String
	field :email, type: String
	field :date, type: Date
	field :time, type: String
	field :in_date, type: String
	field :in_time, type: String
	field :out_date, type: String
	field :out_time, type: String
	field :gst_code, type: String
	field :cu_name, type: String
	field :ag_code, type: String
	field :co_code, type: String
	field :status, type: String



	index(
		[
			[ :hotelid, Mongo::ASCENDING],			
			[ :no, Mongo::ASCENDING],
			[ :bkg_sno, Mongo::ASCENDING],
			[ :rsd_sno, Mongo::ASCENDING]
		],
		unique: true	
	)

	def to_csv
		[
			hotelid, no, bkg_sno, rsd_sno,
			atnd_by, bkd_by, roomno, enq_no,
			add, city, pin, cont_no, email,
			date, time, in_date, in_time, 
			out_date, out_time, gst_code,
			cu_name, ag_code, co_code, status 
		].to_csv
	end	

	def generate_allocations
		indt = Date.strptime(in_date, "%Y-%m-%d")
		oudt = Date.strptime(out_date, "%Y-%m-%d")
		indt.upto oudt do |day|
			RoomAllocation.create(hotelid: hotelid) do |ra|
				ra.roomno = roomno
				ra.date = day
				ra.type = "Bkd"
				ra.resno = no
				ra.ressno = bkg_sno
				ra.resno = rsd_sno
				ra.name = cu_name
				ra.intime = in_time if in_date == day
				ra.outtime = out_time if out_date == day
			end	
		end
	end	
end	