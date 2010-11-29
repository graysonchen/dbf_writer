class BaseFieldWriter
  attr_reader :name, :length, :type

  def initialize(field_name, field_length)
    unless (1..255).include? field_length
      raise ArgumentError, "Field is too large. Length must be 1..255"
    else
      @name, @length, @type = field_name, field_length, 'C'
    end
  end

  def definition(offset)
    columns = []
    columns << @name.upcase
    columns << @type
    columns << offset
    columns << 0 #Reserved
    columns << @length
    columns << 0 #WorkAreaId
    columns << 0 #multiuser
    columns << 0 #Setfield
    columns << 0 #reserved
    columns << 0 #reserved
    columns << 0 #IncludeMdx
    columns.pack('a11aCx2CCx15')
  end


end

