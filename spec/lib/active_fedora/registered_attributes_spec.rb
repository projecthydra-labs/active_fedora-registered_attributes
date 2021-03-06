require 'spec_helper'
require 'active_fedora/registered_attributes'

describe 'ActiveFedora::RegisteredAttributes' do
  class MockDelegateAttribute < ActiveFedora::Base
    include ActiveFedora::RegisteredAttributes

    has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
      m.field "title",  :string
      m.field "description",  :string
      m.field "creator", :string
      m.field "file_names", :string
      m.field "locations", :string
      m.field "created_on", :date
      m.field "modified_on", :date
    end

    attribute :title, {
      datastream: 'properties',
      label: 'Title of your Work',
      hint: "How would you name this?",
      validates: { presence: true }
    }

    attribute :description, {
      datastream: 'properties',
      default: ['One two'],
      multiple: true
    }

    attribute :creator, {
      datastream: 'properties',
      multiple: false,
      writer: lambda{|value| value.reverse }
    }

    attribute :file_names, {
      datastream: 'properties',
      multiple: true,
      writer: lambda{|value| value.reverse }
    }

    def set_locations(value)
      value.dup << '127.0.0.1'
    end
    protected :set_locations

    attribute :locations, {
      datastream: 'properties',
      displayable: false,
      multiple: true,
      writer: :set_locations
    }

    attribute :created_on, {
      datastream: 'properties',
      multiple: false,
      reader: lambda {|value|
        "DATE: #{value}"
      }
    }

    attribute :not_in_the_datastream, {
      multiple: false,
      editable: false,
      displayable: false
    }

    attribute :modified_on, {
      datastream: 'properties',
      multiple: true,
      editable: false,
      reader: lambda {|value|
        "DATE: #{value}"
      }
    }
  end

  class ChildModel < MockDelegateAttribute
    attribute :not_on_parent
  end

  subject { MockDelegateAttribute.new() }

  describe '.registered_attribute_names' do
    let(:expected_attribute_names) {
      ["title", "description", "creator", "file_names", "locations", "created_on", "not_in_the_datastream", "modified_on"]
    }
    it {
      expect(MockDelegateAttribute.registered_attribute_names).to eq(
        expected_attribute_names
      )
    }
  end

  describe '#editable_attributes' do
    let(:expected_attribute_names) {
      [ :title, :description, :creator, :file_names, :locations, :created_on ]
    }
    it 'is all of the attributes that are editable' do
      actual_editable_attributes = subject.editable_attributes.collect {|a| a.name }
      expect(actual_editable_attributes).to eq(expected_attribute_names)
      expect(subject.terms_for_editing).to eq(expected_attribute_names)
    end
  end

  describe '.editable_attributes' do
    it 'delegates to the .attribute_registry' do
      expected_editable_attributes = MockDelegateAttribute.attribute_registry.editable_attributes
      expect(MockDelegateAttribute.editable_attributes).to eq expected_editable_attributes
    end
  end

  describe '.displayable_attributes' do
    it 'delegates to the .attribute_registry' do
      expected_displayable_attributes = MockDelegateAttribute.attribute_registry.displayable_attributes
      expect(MockDelegateAttribute.displayable_attributes).to eq expected_displayable_attributes
    end
  end

  describe '#displayable_attributes' do
    let(:expected_attribute_names) {
      [ :title, :description, :creator, :file_names, :created_on, :modified_on ]
    }
    it 'is all of the attributes that are displayable' do
      actual_displayable_attributes = subject.displayable_attributes.collect {|a| a.name }
      expect(actual_displayable_attributes).to eq(expected_attribute_names)
      expect(subject.terms_for_display).to eq(expected_attribute_names)
    end
  end

  describe '.attribute' do

    context 'for model inheritance' do
      it 'does not add child declared attributes to parent class' do
        expect {
          MockDelegateAttribute.attribute_registry.fetch(:not_on_parent)
        }.to raise_error(KeyError)
      end

      it 'children have parent attributes' do
        expect {
          ChildModel.attribute_registry.fetch(:title)
        }.to_not raise_error(KeyError)
      end

      it 'children have attribute setting from parent' do
        child = ChildModel.new

        expect {
          child.title = 'Hello'
        }.to_not raise_error(NoMethodError)
      end
    end

    it 'handles attributes not delegated to a datastream' do
      subject.not_in_the_datastream = 'World?'
      expect(subject.not_in_the_datastream).to eq('World?')
    end
    it "has creates a setter/getter" do
      subject.title = 'Hello'
      expect(subject.properties.title).to eq([subject.title])
    end

    it "enforces validation when passed" do
      subject.title = nil
      subject.valid?
      expect(subject.errors[:title].size).to eq(1)
    end

    it "allows for default" do
      expect(subject.description).to eq(['One two'])
    end

    it "allows for a reader to intercept the returning of values" do
      date = Date.today
      subject.created_on = date
      expect(subject.properties.created_on).to eq([date])
      expect(subject.created_on).to eq("DATE: #{date}")
    end

    it "allows for a reader to intercept the returning of values" do
      date = Date.today
      subject.created_on = date
      expect(subject.properties.created_on).to eq([date])
      expect(subject.created_on).to eq("DATE: #{date}")
    end

    it "allows for a writer to intercept the setting of values" do
      text = 'hello world'
      subject.creator = 'hello world'
      expect(subject.properties.creator).to eq([text.reverse])
      expect(subject.creator).to eq(text.reverse)
    end

    it "allows for a writer to intercept the setting of values" do
      values = ['foo.rb', 'bar.rb']
      subject.file_names = values
      expect(subject.properties.file_names).to eq(values.reverse)
      expect(subject.file_names).to eq(values.reverse)
    end

    it "intercepts blanks and omits them" do
      values = ['foo.rb', '', 'bar.rb', '']
      expected_values = ['foo.rb', 'bar.rb']
      subject.description = values
      expect(subject.properties.description).to eq(expected_values)
      expect(subject.description).to eq(expected_values)
    end

    it "allows for a writer that is a symbol" do
      values = ['South Bend', 'State College', 'Minneapolis']
      expected_values = values.dup
      expected_values << '127.0.0.1'
      subject.locations = values
      expect(subject.properties.locations).to eq(expected_values)
      expect(subject.locations).to eq(expected_values)
    end
  end

end
