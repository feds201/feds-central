import { Entity, PrimaryGeneratedColumn, Column } from "typeorm"

@Entity("match")
export class Match {
  @PrimaryGeneratedColumn("identity")
  id: number

  @Column("integer")
  matchNumber: number

  @Column("text")
  matchType: string

  @Column("text")
  allianceColor: string

  @Column("integer")
  allianceRobotNumber: number

  @Column("integer")
  teamNumber: number
}
