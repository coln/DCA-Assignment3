#!/usr/bin/env python

""" Assignment 2

Simple MIPS Disassembler for the 29 Core Instructions
"""

import sys

# Errors
class UnknownOpcodeError(Exception):
   """ Raised when the disassembler encounters an unknown opcode """
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
   
   @staticmethod
   def hex2bin(num, width=32):
      """ Takes hex string, outputs bin string """
      return ('{0:0' + str(width) + 'b}').format(int(num, 16))
   
   @staticmethod
   def int2hex(num, width=16):
      """ Takes integer, outputs hex string """
      # Python trick to divide and ceil rather than divide and floor
      width = -(-width // 4)
      return ('0x{0:0' + str(width) + 'X}').format(num)
   
   @staticmethod
   def bin2int_signed(value, length):
       """ Compute the 2's compliment of int value """
       # If sign bit is set compute the negative value
       if (value & (1 << (length - 1))) != 0:
           value = value - (1 << length)
       return value


class Disassembler:
   # MIPS Definitions
   BASE_ADDRESS = 0x00400000
   WIDTH = 32
   DEPTH = 256
   RTYPE = "rtype"
   ITYPE = "itype"
   JTYPE = "jtype"
   UNKNOWNTYPE = "unknown"
   
   IMM_WIDTH = 16

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
   rtype = [ 'add', 'addu', 'and', 'jr', 'nor', 'or',
             'slt', 'sltu', 'sll', 'srl', 'sub', 'subu' ]
   itype = [ 'addi', 'addiu', 'andi', 'beq', 'bne', 'lbu', 'lhu',
             'lui', 'lw', 'ori', 'slti', 'sltiu', 'sb', 'sh', 'sw' ]
   jtype = [ 'j', 'jal' ]
   line_number = 0
   dsm = []
   
   
   def __init__(self, filename=""):
      self.filename = filename
   
   def setFileInput(self, filename):
      self.filename = filename
   
   def disassembleFile(self):
      """ Second pass of the file. Most errors should be resolved """
      with open(self.filename, 'r') as file:
         for line in file:
            # Only get the necessary "XXX : INSTR" lines
            if (line[0] != ' ' and line[0] != '\t') or line.strip()[0] == '[':
               continue
            self.disassembleLine(line)
      
   def disassembleLine(self, line):
      # Cleanup line input
      line = line.split(":")
      for i in range(len(line)):
         line[i] = line[i].strip()
      
      # Get the line number
      line_number = int(line[0], 16)
      
      # Get the instruction excluding the last ";"
      instruction = line[1][:-1]
      binary = Utility.hex2bin(instruction)
      
      # Function is only used if opcode = RTYPE
      opcode = int(binary[0:6], 2)
      function = int(binary[26:], 2)
      type = self.identifyType(opcode, function)
      
      if type == self.RTYPE:
         name, src, temp, dest, shift, function = self.decodeInstruction(type, binary)
         if name == 'jr':
            self.dsm.append(name + " " + src)
         elif name in ['sll', 'srl']:
            self.dsm.append(name + " " + dest + ", " + temp + ", " + str(shift))
         else:
            self.dsm.append(name + " " + dest + ", " + src + ", " + temp)
         
      elif type == self.ITYPE:
         name, src, temp, imm = self.decodeInstruction(type, binary)
         if name in ['beq', 'bne']:
            self.dsm.append(name + " " + src + ", " + temp + ", " + Utility.int2hex(imm))
         elif name in ['lbu', 'lhu', 'lw', 'sb', 'sh', 'sw']:
            imm = Utility.bin2int_signed(imm, self.IMM_WIDTH)
            self.dsm.append(name + " " + temp + ", " + str(imm) + "(" + src + ")")
         elif name == 'lui':
            self.dsm.append(name + " " + temp + ", " + Utility.int2hex(imm))
         else:
            self.dsm.append(name + " " + temp + ", " + src + ", " + Utility.int2hex(imm))
      elif type == self.JTYPE:
         name, address = self.decodeInstruction(type, binary)
         self.dsm.append(name + " " + Utility.int2hex(address, width=26))
   
   
   
   
   def identifyType(self, opcode, function):
      instruction = self.getInstructionFromOpcode(opcode, function)
      if instruction in self.rtype:
         return self.RTYPE
      elif instruction in self.itype:
         return self.ITYPE
      elif instruction in self.jtype:
         return self.JTYPE
      else:
         error = 'Unknown opcode: "' + Utility.int2hex(opcode, width=2)
         error += '" line #' + str(self.line_number)
         raise UnknownOpcodeError(error)
         return self.UNKNOWNTYPE
   
   def decodeInstruction(self, type, binary):
      opcode = int(binary[:6], 2)
      function = int(binary[26:], 2)
      name = self.getInstructionFromOpcode(opcode, function)
      
      if type == self.RTYPE:
         src = "$" + str(int(binary[6:11], 2))
         temp = "$" + str(int(binary[11:16], 2))
         dest = "$" + str(int(binary[16:21], 2))
         shift = int(binary[21:26], 2)
         return (name, src, temp, dest, shift, function)
      
      elif type == self.ITYPE:
         src = "$" + str(int(binary[6:11], 2))
         temp = "$" + str(int(binary[11:16], 2))
         imm = int(binary[16:], 2)
         return (name, src, temp, imm)
      
      elif type == self.JTYPE:
         address = int(binary[6:], 2)
         return (name, address)
         
      return None
   
   def getInstructionFromOpcode(self, opcode, function=0):
      if opcode == 0:
         for name, value in self.functions.items():
            if value == function:
               return name
      else:
         for name, value in self.opcodes.items():
            if value == opcode:
               return name
      return ""
      
   
   def exportData(self, filename):
      """ Writes the assembled code (in list "self.dsm") in chunks """
      with open(filename, 'w') as outputFile:
         for line in self.dsm:
            outputFile.write(line + "\n")





# Main code   
def main():
   for i in range(1, len(sys.argv)):
      disassembler = Disassembler()
      disassembler.setFileInput(sys.argv[i])
      
      try:
         disassembler.disassembleFile()
      except UnknownOpcodeError as err:
         print(err)
         return 2
      
      disassembler.exportData("dsm.txt")      

if __name__ == "__main__":
   sys.exit(main())