def remove_space_in_hex_file(input_file, output_file):
    with open(input_file, 'r') as file:
        data = file.read()

    cleaned_data = []
    space_count = 0

    for char in data:
        if char == ' ':
            space_count += 1
            if space_count % 4 == 0:
                cleaned_data.append(char)
        elif char == '\n':
            cleaned_data.append(char)
            space_count = 0
        else:
            cleaned_data.append(char)
    
    cleaned_data = ''.join(cleaned_data)

    with open(output_file, 'w') as file:
        file.write(cleaned_data)

def convert_little_to_big_endian(input_file, output_file):
    with open(input_file, 'r') as file:
        data = file.read()

    # 공백을 기준으로 데이터를 분리
    bytes_list = data.split()

    # 변환된 바이트를 저장할 리스트
    converted_bytes = []

    # 각 4 바이트 블록에 대해 반복
    for i in range(0, len(bytes_list), 4):
        # 4 바이트를 결합하여 big endian 순서로 재배열
        big_endian_block = bytes_list[i+3] + " " + bytes_list[i+2] + " " + bytes_list[i+1] + " " + bytes_list[i]
        # 재배열된 바이트 블록을 리스트에 추가
        converted_bytes.append(big_endian_block)

    # 결과를 공백으로 구분하여 문자열로 합치기
    swapped_data = '\n'.join(' '.join(converted_bytes[i:i+4]) for i in range(0, len(converted_bytes), 4))

    with open(output_file, 'w') as file:
        file.write(swapped_data)

input_file_path = '/home/kbkang/xcelium_tb/cv32e40p/tests/custom/dhrystone/dhrystone.hex'
mid_file_path = '/home/kbkang/xcelium_tb/dhrystone_mid.hex'
output_file_path = '/home/kbkang/xcelium_tb/cv32e40p/tests/custom/dhrystone/dhrystone.hex'

convert_little_to_big_endian(input_file_path, mid_file_path)
remove_space_in_hex_file(mid_file_path, output_file_path)