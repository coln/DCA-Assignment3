#!/usr/bin/env python

""" Assignment 2

Simple MIPS Assembler for the 29 Core Instructions
"""

import os
import sys
import math

# Errors
class MultipleLabelError(Exception):
   """ Raised when there are multiple labels with the same name """
   def __init__(self, msg):
      self.msg = msg
   def __str__(self):
      return str(self.msg)
      
class UnknownInstructionError(Exception):
   """ Raised when assembler encounters an unknown instruction """
   def __init__(self, msg):
      self.msg = msg
   def __str__(self):
      return str(self.msg)

# Helper functions
class Utility:
   @staticmethod
   def bin2hex(num):
      """ Takes binary string, outputs hex string without the prefix '0x' """
      return '{0:08X}'.format(int(num, 2))


class Assembler:
   # MIPS Definitions
   BASE_ADDRESS = 0x00400000
   WIDTH = 32
   DEPTH = 256
   COMMENT_CHAR = ';'

   registers = [
      "zero",   # 0
      "at",     # 1
      "v0", "v1",  # 2-3
      "a0", "a1", "a2", "a3",  # 4-7
      "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",  # 8-15
      "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7",  # 16-23
      "t8", "t9",  # 24-25
      "k0", "k1",  # 26-27
      "gp",  # 28
      "sp",  # 29
      "fp",  # 30
      "ra"   # 31
   ]
   opcodes = {
      'add': 0x00,
      'addi': 0x08,
      'addiu': 0x09,
      'addu': 0x00,
      'and': 0x00,
      'andi': 0x0C,
      'beq': 0x04,
      'bne': 0x05,
      'j': 0x02,
      'jal': 0x03,
      'jr': 0x00,
      'lbu': 0x24,
      'lhu': 0x25,
      'lui': 0x0F,
      'lw': 0x23,
      'nor': 0x00,
      'or': 0x00,
      'ori': 0x0D,
      'slt': 0x00,
      'slti': 0x0A,
      'sltiu': 0x0B,
      'sltu': 0x00,
      'sll': 0x00,
      'srl': 0x00,
      'sb': 0x28,
      'sh': 0x29,
      'sw': 0x2B,
      'sub': 0x00,
      'subu': 0x00
   }
   functions = {
      'add': 0x20,
      'addu': 0x21,
      'and': 0x24,
      'jr': 0x08,
      'nor': 0x27,
      'or': 0x25,
      'slt': 0x2A,
      'sltu': 0x2B,
      'sll': 0x00,
      'srl': 0x02,
      'sub': 0x22,
      'subu': 0x23
   }
   line_number = 0
   labels = {}
   asm = []
   
   
   # Instruction types
   class RType:
      OPCODE_WIDTH = 6
      SOURCE_WIDTH = 5
      DEST_WIDTH = 5
      TEMP_WIDTH = 5
      SHIFT_WIDTH = 5
      FUNC_WIDTH = 6
      
      @staticmethod
      def format(opcode, src, temp, dest, shift, function):
         src = Assembler.getRegisterNumber(src)
         temp = Assembler.getRegisterNumber(temp)
         dest = Assembler.getRegisterNumber(dest)
         shift = int(shift)
         
         instruction = ('{0:0' + str(Assembler.RType.OPCODE_WIDTH) + 'b}').format(opcode)
         instruction += ('{0:0' + str(Assembler.RType.SOURCE_WIDTH) + 'b}').format(src)
         instruction += ('{0:0' + str(Assembler.RType.TEMP_WIDTH) + 'b}').format(temp)
         instruction += ('{0:0' + str(Assembler.RType.DEST_WIDTH) + 'b}').format(dest)
         instruction += ('{0:0' + str(Assembler.RType.SHIFT_WIDTH) + 'b}').format(shift)
         instruction += ('{0:0' + str(Assembler.RType.FUNC_WIDTH) + 'b}').format(function)
         
         # Convert binary string to hex with "0x"
         return Utility.bin2hex(instruction)

   class IType:
      IMM_WIDTH = 16
      
      @staticmethod
      def format(opcode, src, temp, immediate):
         src = Assembler.getRegisterNumber(src)
         temp = Assembler.getRegisterNumber(temp)
         
         # Convert negative offsets to two's complement
         immediate = immediate if immediate >= 0 else (1 << Assembler.IType.IMM_WIDTH) + immediate
         
         instruction = ('{0:0' + str(Assembler.RType.OPCODE_WIDTH) + 'b}').format(opcode)
         instruction += ('{0:0' + str(Assembler.RType.SOURCE_WIDTH) + 'b}').format(src)
         instruction += ('{0:0' + str(Assembler.RType.TEMP_WIDTH) + 'b}').format(temp)
         instruction += ('{0:0' + str(Assembler.IType.IMM_WIDTH) + 'b}').format(immediate)
         
         # Convert binary string to hex with "0x"
         return Utility.bin2hex(instruction)

   class JType:
      ADDR_WIDTH = 26
      
      @staticmethod
      def format(opcode, address):
         # Convert negative addresses to two's complement
         address = address if address >= 0 else (1 << JType.ADDR_WIDTH) + address
         
         instruction = ('{0:0' + str(Assembler.RType.OPCODE_WIDTH) + 'b}').format(opcode)
         instruction += ('{0:0' + str(Assembler.JType.ADDR_WIDTH) + 'b}').format(address)
         
         # Convert binary string to hex with "0x"
         return Utility.bin2hex(instruction)
   
   
   
   def __init__(self, filename=""):
      self.filename = filename
   
   def setFileInput(self, filename):
      self.filename = filename
   
   @staticmethod
   def getRegisterNumber(reg):
      if str(reg).isdigit():
         return int(reg)
      else:
         try:
            return int(Assembler.registers.index(reg))
         except ValueError:
            return 0
   
   def getOffsetFromArg(self, arg, line_number):
      """ Try evaluating the offset as a number. If that fails
      then the offset is a label
      """
      offset = 0
      if arg[:2].lower() == '0x':
         offset = int(arg[2:], 16)
      else:
         label_line = self.labels[arg]
         offset = label_line - line_number
      return offset

   def getAddressFromArg(self, arg):
      """ Try evaluating the address as a hex number. If that fails
      then the address is a label
      """
      offset = 0
      try:
         offset = int(arg, 16)
      except ValueError:
         label_line = self.labels[arg] - 1
         offset = self.BASE_ADDRESS + label_line
      return offset
   
   
   def processFile(self):
      """ First pass through the file. Evaluate expressions line-by-line """
      self.line_number = 1
      with open(self.filename, 'r') as file:
         for line in file:
            self.processLine(line)
            self.line_number += 1
   
   def processLine(self, line):
      line = line.lower()
      line = line.strip()
      line = line.split(self.COMMENT_CHAR, 1)[0]  # Remove comments
      line = line.split(" ")  # Separate components
      
      # Empty line (don't count it)
      if len(line) == 1 and line[0] == '':
         self.line_number -= 1
         return
      
      # Gather all labels
      if line[0][-1] == ":":
         label = line[0][:-1]
         if label in self.labels:
            raise MultipleLabelError('Label "' + label + '" is already defined! Line #' + str(self.line_number))
            return
         else:
            self.labels[label] = self.line_number
            self.line_number -= 1
         return
         
      # Check for valid instruction
      opcode = line[0]
      if not opcode in self.opcodes:
         raise UnknownInstructionError('Unknown instruction "' + opcode + '" at line #' + str(self.line_number))
         return
      
   def assembleFile(self):
      """ Second pass of the file. Most errors should be resolved """
      self.line_number = 1
      with open(self.filename, 'r') as file:
         for line in file:
            self.assembleLine(line)
            self.line_number += 1
      
   def assembleLine(self, line):
      """ Where the magic happens """
      line = line.strip()
      line = line.split(self.COMMENT_CHAR, 1)[0]  # Remove comments
      line = line.split(" ")  # Split line into parts
      
      # Empty line
      if len(line) == 1 and line[0] == '':
         self.line_number -= 1
         return
      
      # Skip label definitions and don't count line number
      if line[0][-1] == ":":
         self.line_number -= 1
         return
      
      # Evaluate each instruction
      # Pre-fetch values so I don't have to do it each if-statement
      instruction = line[0]
      opcode = self.opcodes[instruction]
      function = ""
      arg1 = ""
      arg2 = ""
      arg3 = ""
      # Ignore index-out-of-bounds errors
      try:
         arg1 = line[1].strip("$").strip(",")
         arg2 = line[2].strip("$").strip(",")
         arg3 = line[3].strip("$").strip(",")
      except IndexError:
         pass
      try:
         function = self.functions[instruction]
      except KeyError:
         pass
      
      if instruction in ['add', 'addu', 'and', 'or', 'nor', 'slt', 'sltu', 'sub', 'subu']:
         dest = arg1
         src = arg2
         temp = arg3
         self.asm.append(Assembler.RType.format(opcode, src, temp, dest, 0, function))
      elif instruction in ['addi', 'addiu', 'andi', 'ori', 'slti', 'sltiu']:
         temp = arg1
         src = arg2
         imm = arg3
         imm = self.getOffsetFromArg(imm, self.line_number)
         self.asm.append(Assembler.IType.format(opcode, src, temp, imm))
      elif instruction in ['beq', 'bne']:
         src = arg1
         temp = arg2
         offset = arg3
         offset = self.getOffsetFromArg(offset, self.line_number + 1)
         self.asm.append(Assembler.IType.format(opcode, src, temp, offset))
      elif instruction in ['j', 'jal']:
         address = arg1
         address = self.getAddressFromArg(address)
         self.asm.append(Assembler.JType.format(opcode, address))
      elif instruction == 'jr':
         src = arg1
         self.asm.append(Assembler.RType.format(opcode, src, 0, 0, 0, function))
      elif instruction in ['lbu', 'lhu', 'lw', 'sb', 'sh', 'sw']:
         temp = arg1
         args = arg2.split('(')
         src = args[1].strip(')').strip("$").strip(',')
         # Get the offset in either hex or decimal representation
         if args[0][:2].lower() == '0x':
            offset = int(args[0][2:], 16)
         else:
            offset = int(args[0])
         self.asm.append(Assembler.IType.format(opcode, src, temp, offset))
      elif instruction == 'lui':
         temp = arg1
         imm = arg2
         imm = self.getOffsetFromArg(imm, self.line_number)
         self.asm.append(Assembler.IType.format(opcode, 0, temp, imm))
      elif instruction in ['sll', 'srl']:
         dest = arg1
         temp = arg2
         shift = arg3
         self.asm.append(Assembler.RType.format(opcode, 0, temp, dest, shift, function))
   
   def exportData(self, filename):
      """ Writes the assembled code (in list "self.asm") in chunks """
      with open(filename, 'w') as outputFile:
         output = "WIDTH=" + str(self.WIDTH) + ";\n"
         output += "DEPTH=" + str(self.DEPTH) + ";\n\n"
         output += "ADDRESS_RADIX=HEX;\n"
         output += "DATA_RADIX=HEX;\n\n"
         output += "CONTENT BEGIN\n"
         outputFile.write(output)
         
         numBits = math.ceil(math.log(self.DEPTH, 2))
         numHex = int(numBits / 4)
         
         i = 0
         for i in range(len(self.asm)):
            output = "    "
            output += '{0:03X}'.format(i)
            output += "  :   ";
            output += self.asm[i]
            output += ";"
            output += "\n"
            outputFile.write(output)
            
         output = "    [" + ('{0:0' + str(numHex) + 'X}').format(i + 1)
         output += ".." + ('{0:0' + str(numHex) + 'X}').format(self.DEPTH - 1) + "]"
         output += "  :   ";
         output += ('{0:0' + str(int(self.WIDTH / 4)) + 'X}').format(0) + ";"
         output += "\n"
         output += "END;\n"
         outputFile.write(output)
         print("Success!")
         print("Assembled file output: " + os.path.abspath(outputFile.name))




# Main code   
def main():
   assembler = Assembler()
   assembler.setFileInput(sys.argv[1])
   try:
      assembler.processFile()
   except (MultipleLabelError, UnknownInstructionError) as err:
      print(err)
      return 2
   
   assembler.assembleFile()
   assembler.exportData(sys.argv[2])      

if __name__ == "__main__":
   sys.exit(main())