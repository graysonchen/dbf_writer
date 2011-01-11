require 'writers/field_writers'

# Generates the binary header and data of the DBF.
#
# Should I split in a Header class since is somewhat complex and only pass field info as needed?
# That could lead to some tight coupling tho.

class FileWriter

  # An array that store the field definitions
  attr_reader :fields

  def initialize
    @fields, @rows, @data = [], [], ""
    @header = [3]
  end

  # Adds a field to the file definition.
  #
  # Usage:
  #
  # * _name_: can be either a string or a symbol.
  # * _options_: is a hash that takes the following parameters (See the field writers for more info):
  #     :type => [:character, :date] is the field type. character is assumed by default
  #     :length => integer, the length of the character field (default: 50)
  def add_field(field_name, options = {})
    options = parse_options(options)
    @fields << BaseFieldWriter.field_for(field_name.to_s, options)
    self
  end

  # Add a row of data to the definiton
  def add_row(*row)
    @rows << row
  end

  # Creates a binary representation. Including header + data.
  def to_binary_string
    header
    row_data
    eof unless @rows.empty?
    @data
  end

  private
  def parse_options(options)
    options[:length] ||= 50
    options[:type] ||= :character
    options
  end

  def column_definitions
    offset = 1
    arr = @fields.map do |field|
      current_offset, offset = offset, offset + field.length
      field.definition(current_offset)
    end
    @data << arr.join('')
  end

  def header
    current_date
    @header << @rows.size  # total number of records
    field_info
    @data << @header.pack('CCCCVvvxxxxxxxxxxxxxxxxxxxx')
    column_definitions
    @data << "\x0D"
  end

  def current_date
    @header.push 10, 11, 4 # this should be year, month, day
  end

  def field_info
    @header << (@fields.size * 32 + 33) #size of fields descriptors
    @header << @fields.reduce(1) { |sum, field| sum + field.length} #field definitions
  end

  def row_data
    @rows.each do |row|
      write_row(row)
    end
  end

  def write_row(row)
    row.each_with_index {|data, index| @data << @fields[index].data(data) }
  end

  def eof
    @data << "\x1A"
  end

end

