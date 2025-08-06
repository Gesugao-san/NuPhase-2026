import { toFixed } from 'tgui-core/math';
import { useBackend} from "../backend";
import { LabeledList, Box, Section, Flex, ProgressBar } from 'tgui-core/components';
import { formatSiUnit } from "tgui-core/format";
import { Window } from "../layouts";

type Alarm = {
  content: string;
  alarm_color: string;
  is_bold: boolean;
}

type Gas = {
  name: string;
  color: string;
  amount: number;
}

type InputData = {
  gases: Gas[];
  alarmlist: Alarm[];
  power_load: number;
  thermal_load: number;
  neutron_rate: number;
  energy_rate: number;
  xray_flux: number;
  radiation: number;
  chamber_temperature: number;
  containment_consumption: number;
  containment_temperature: number;
  containment_volume: number;
  containment_charge: number;
  moderator_position: number;
  reflector_position: number;
}

export const GeneralReactorMonitor = (props: any, context: any) => {
  const { act, data } = useBackend<InputData>(context);
  const gasMaxAmount = Math.max(1, ...data.gases.map((Gas) => Gas.amount));
  return (
    <Window width = {700} height = {530} theme="ntos">
      <Window.Content>
        <Flex>
          <Flex.Item height={40}>
            <Section title = "Centralized Warning Log"
              fill
              backgroundColor="black">
              {data.alarmlist.map(Alarm => (
                <Box
                  mb = {2}
                  textColor = {Alarm.alarm_color}
                  bold = {Alarm.is_bold}>
                  {Alarm.content}
                </Box>
              ))}
            </Section>
          </Flex.Item>
          <Flex.Item height={20}>
            <Section title = " General Data">
              <LabeledList>
                <LabeledList.Item label = "Total Power Generation">
                  {formatSiUnit(data.power_load, 1, "W")}
                </LabeledList.Item>
                <LabeledList.Item label = "Turbine Energy Flow">
                  {formatSiUnit(data.thermal_load, 1, "W")}
                </LabeledList.Item>
                <LabeledList.Item label = "Neutron Generation Rate">
                  <ProgressBar
                    ranges={{
                    bad: [5, Infinity],
                    good: [-1, 1],
                    average: [-3, -1],
                    teal: [-10, -3],
                    }}
                    minValue = {-10}
                    maxValue = {10}
                    value={data.neutron_rate}>
                  {data.neutron_rate}
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label = "Temperature Rate">
                  <ProgressBar
                    ranges={{
                    bad: [-Infinity, -2.5],
                    good: [-0.5, 0.5],
                    average: [2.5, Infinity],
                    }}
                    minValue = {-5}
                    maxValue = {5}
                    value={data.energy_rate}>
                  {data.energy_rate} eV/s ({(data.chamber_temperature*0.00008).toFixed(1)} eV)
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label = "External Radiation Level">
                  {data.radiation} Sv/hour
                </LabeledList.Item>
                <LabeledList.Item label = "XRay Flux">
                  {data.xray_flux}
                </LabeledList.Item>
                <LabeledList.Item label = "Chamber Temperature">
                  {formatSiUnit(data.chamber_temperature, 1, "K")}
                </LabeledList.Item>
              </LabeledList>
            </Section>
            <Section title = " Containment Data">
              <LabeledList>
                <LabeledList.Item label = "Shield Power Consumption">
                  {formatSiUnit(data.containment_consumption, 1, "W")}
                </LabeledList.Item>
                <LabeledList.Item label = "Shield Temperature">
                  {data.containment_temperature}K
                </LabeledList.Item>
                <LabeledList.Item label = "Shield Battery Charge">
                  {data.containment_charge}%
                </LabeledList.Item>
                <LabeledList.Item label = "Shield Internal Volume">
                  {data.containment_volume}m3
                </LabeledList.Item>
                <LabeledList.Item label = "Moderator Position">
                  {data.moderator_position*100}%
                </LabeledList.Item>
                <LabeledList.Item label = "Reflector Position">
                  {data.reflector_position*100}%
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Flex.Item>
          <Flex.Item height={20}>
            <Section title = " Plasma Spectrometry">
              <LabeledList>
                {data.gases.map((Gas) => (
                    <LabeledList.Item label={Gas.name}>
                      <ProgressBar
                        color={Gas.color}
                        value={Gas.amount}
                        minValue={0}
                        maxValue={gasMaxAmount}>
                        {toFixed(Gas.amount/gasMaxAmount, 2) + '%'}
                      </ProgressBar>
                    </LabeledList.Item>
                ))}
              </LabeledList>
            </Section>
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  )
}
