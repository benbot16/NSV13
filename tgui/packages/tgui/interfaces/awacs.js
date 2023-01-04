// AWACS Console
// A modified DRADIS console that lets ATC command pilots

import { useBackend } from '../backend';
import { Box, Button, Section, ProgressBar, Knob, Flex, Tabs, LabeledList, Map, StarButton } from '../components';
import { Window } from '../layouts';

export const awacs = (props, context) => {
  let dradisContent = DradisContent(props, context);

  return (
    <Window
      theme="hackerman"
      width={700}
      height={750}>
      <Window.Content scrollable>
        <Flex height="100%">
          <Flex.Item class="awacs_dradis" grow id="radar">
            {dradisContent}
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

// This handles the DRADIS part of the display, and it's a modified version of the standard DRADIS console
export const DradisContent = (props, context) => {
  const { act, data } = useBackend(context);

  const drawShips = ship => {
    let borderType = "1px solid "+ship.colour;
    let markerStyle = {
      height: '1px',
      position: 'absolute',
      left: ship.x*scale_factor+'px',
      bottom: ship.y*scale_factor+'px',
      border: borderType,
      opacity: ship.opacity,
      transition: "all 0.5s ease-out",
    };
    let markerType = "star_marker"+"_"+ship.alignment;
    return (
      <li key={ship.id}>
        {!!ship.name && (
          <Button unselectable="on" style={markerStyle} className={markerType}
            content="" onClick={() => act('hail', { target: ship.id })}>
            <span class="star_label">
              <p>{ship.name}</p>
            </span>
          </Button>
        )};
      </li>
    );
  };

  const DradisMap = (ships, zoom_factor, width_mod, focus_x, focus_y) => {
    let scale_factor = 5*zoom_factor;
    let multiplier = 562.5*zoom_factor;
    let rangeStyle = "left:"+focus_x*scale_factor+"px;bottom:"+focus_y*scale_factor+"px; width:"+width_mod*multiplier+"px; height:"+width_mod*multiplier+"px;margin-bottom:"+(-1)*((width_mod*multiplier)/2)+"px;margin-left:"+(-1)*((width_mod*multiplier)/2)+"px;";
    let ShipMap = (ships).map(drawShips);
    return (
      <Map initial_focus_x={focus_x}
        initial_focus_y={focus_y}
        initial_scale_factor={scale_factor}
        grid="1">
        {ShipMap}
        <div id="rangeCircle" style={rangeStyle} />
      </Map>
    );
  };

  // Floats representing the different alpha values for different filtered objects.
  let showFriendlies = data.showFriendlies;
  let showEnemies = data.showEnemies;
  let focus_x = data.focus_x;
  let focus_y = data.focus_y;
  let zoom_factor = data.zoom_factor;
  let zoom_factor_min = data.zoom_factor_min;
  let zoom_factor_max = data.zoom_factor_max;
  let scale_factor = zoom_factor*5;
  let dradis_targeting = data.dradis_targeting;
  let dradis = DradisMap(data.ships, zoom_factor, data.width_mod, focus_x, focus_y);

  // Our actual "DRADIS" display
  return (
    <Section
      title="DRADIS Settings:"
      buttons={(
        <>
          <Button
            icon="search-plus"
            onClick={() => act('zoomin')} />
          <Button
            icon="search-minus"
            onClick={() => act('zoomout')} />
          <Button
            content="Re-focus"
            icon="camera"
            onClick={() => location.reload()} />
        </>
      )}>
      Allies:
      <Knob
        inline
        mx={1}
        color={!!showFriendlies && 'green'}
        value={showFriendlies}
        unit="scan strength"
        minValue="0"
        maxValue="100"
        step={1}
        stepPixelSize={1}
        onDrag={(e, value) => act('showFriendlies', { alpha: value })} />
      Enemies:
      <Knob
        inline
        mx={1}
        color={!!showEnemies && 'green'}
        value={showEnemies}
        unit="scan strength"
        minValue="0"
        maxValue="100"
        step={1}
        stepPixelSize={1}
        onDrag={(e, value) => act('showEnemies', { alpha: value })} />
      Zoom:
      <Knob
        inline
        mx={1}
        color="green"
        value={zoom_factor*100}
        unit="%"
        minValue={zoom_factor_min*100}
        maxValue={zoom_factor_max*100}
        step={1}
        stepPixelSize={1}
        onDrag={(e, value) => act('setZoom', { zoom: value })} />
      {dradis}
    </Section>
  );
};

export const FighterDisplay = (props, context) => {
  const { act, data } = useBackend(context);

  const listFriendlyShips = ship => {
  };

  return (
    <Section
      title="Available Aircraft:">
      map
    </Section>
  );
};
