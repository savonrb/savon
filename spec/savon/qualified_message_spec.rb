# frozen_string_literal: true
require "spec_helper"

module Savon
  RSpec.describe QualifiedMessage, "#to_hash" do

    context "if a key ends with !" do
      let(:used_namespaces) { {} }
      let(:key_converter) { :camelcase }
      let(:types) { {} }

      it "restores the ! in a key" do
        message = described_class.new(types, used_namespaces, key_converter)
        resulting_hash = message.to_hash({:Metal! => "<Nice/>"}, ["Rock"])

        expect(resulting_hash).to eq({ :Metal! => "<Nice/>" })
      end

      it "properly handles special keys when namespaces are present" do
        used_namespaces = {
          %w(tns Foo) => 'ns',
          %w(tns Foo Bar) => 'ns'
        }

        hash = {
          :foo => {
            :bar => {
              :zing => 'pow'
            },
            :cash => {
              :@attr1 => 'val1',
              :content! => 'Chunky Bacon'
            },
            :attributes! => {
              :bar => { :attr2 => 'val2' },
            },
            :"self_closing/" => '',
            :order! => [:cash, :bar, :"self_closing/"]
          }
        }

        good_result = {
          "ns:Foo" => {
            'ns:Bar' => { :zing => "pow" },
            :cash => {
              :@attr1 => "val1",
              :content! => "Chunky Bacon"
            },
            :attributes! => {
              'ns:Bar' => { :attr2 => 'val2' }
            },
            :"self_closing/" => '',
            :order! => [:cash, 'ns:Bar', :"self_closing/"]
          }
        }

        good_xml = %(<ns:Foo><Cash attr1="val1">Chunky Bacon</Cash><ns:Bar attr2="val2"><Zing>pow</Zing></ns:Bar><SelfClosing/></ns:Foo>)

        message = described_class.new(types, used_namespaces, key_converter)
        resulting_hash = message.to_hash(hash, ['tns'])
        xml = Gyoku.xml(resulting_hash, key_converter: key_converter)

        expect(resulting_hash).to eq good_result
        expect(xml).to eq good_xml
      end

      it "uses schema order when :order! is set to :use_schema" do
        used_namespaces = {
          %w(tns Foo) => 'ns'
        }

        hash = {
          :foo => {
            :order! => :use_schema,
            :bar => 'zing',
            :cash => 'pow'
          }
        }

        good_result = {
          "ns:Foo" => {
            :order! => [:bar, :cash],
            :bar => 'zing',
            :cash => 'pow'
          }
        }

        message = described_class.new(types, used_namespaces, key_converter)
        resulting_hash = message.to_hash(hash, ['tns'])

        expect(Gyoku.xml(resulting_hash, key_converter: key_converter)).to eq %(<ns:Foo><Bar>zing</Bar><Cash>pow</Cash></ns:Foo>)
        expect(resulting_hash).to eq good_result
        
      end

      it "properly handles boolean false" do
        used_namespaces = {
          %w(tns Foo) => 'ns'
        }

        hash = {
          :foo => {
            :falsey => {
              :@attr1 => false,
              :content! => false
            }
          }
        }

        good_result = {
          "ns:Foo" => {
            :falsey => {
              :@attr1 => false,
              :content! => false
            }
          }
        }

        good_xml = %(<ns:Foo><Falsey attr1="false">false</Falsey></ns:Foo>)

        message = described_class.new(types, used_namespaces, key_converter)
        resulting_hash = message.to_hash(hash, ['tns'])
        xml = Gyoku.xml(resulting_hash, key_converter: key_converter)

        expect(resulting_hash).to eq good_result
        expect(xml).to eq good_xml
      end
    end

  end
end
