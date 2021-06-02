SPI_SLAVE_0 = $10
SPI_SLAVE_1 = $20
SPI_SLAVE_2 = $40
SPL_SLAVE_3 = $80
SPI_SLAVE_NONE = $00

.global spi_init
.global spi_transfer_byte
.global spi_select_slave
.global spi_deselect_slave
